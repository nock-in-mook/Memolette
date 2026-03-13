import SwiftUI
import SwiftData

extension Notification.Name {
    static let switchToTab = Notification.Name("switchToTab")
}

// 上半分ペインの表示モード
enum TopPaneMode {
    case newInput    // 新規メモ入力
    case preview     // 既存メモ閲覧
    case editing     // 既存メモ編集中
}

struct MemoInputView: View {
    @Bindable var viewModel: MemoInputViewModel
    @Binding var focusInput: Bool
    @Binding var previewingMemo: Memo?
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Tag.name) private var tags: [Tag]
    @FocusState private var isTextEditorFocused: Bool

    // 既存メモ編集中かどうか
    @State private var isEditingExisting = false
    @State private var editText: String = ""
    @State private var editTitle: String = ""

    // 新規タグ作成シート
    @State private var showNewTagSheet = false
    @State private var newTagIsChild = false
    // 全画面編集
    @State private var showFullEditor = false
    // 削除確認ダイアログ
    @State private var showDeleteAlert = false
    // ルーレット展開状態
    @State private var showParentDial = false
    @State private var showChildDial = false
    @State private var childExternalDragY: CGFloat? = nil
    @AppStorage("dialDefault") private var dialDefault: Int = 0

    private var mode: TopPaneMode {
        if previewingMemo != nil {
            return isEditingExisting ? .editing : .preview
        }
        return .newInput
    }

    // 現在表示中のテキスト
    private var currentText: String {
        mode == .newInput ? viewModel.inputText : editText
    }

    // 保存ボタンが押せるか
    private var canSave: Bool {
        switch mode {
        case .newInput: return viewModel.canClear
        case .editing: return true
        case .preview: return false
        }
    }

    private func tabIndex(for tagID: UUID?) -> Int {
        guard let tagID = tagID else { return 0 }
        let parentTags = tags.filter { $0.parentTagID == nil }
        if let idx = parentTags.firstIndex(where: { $0.id == tagID }) {
            return idx + 1
        }
        return 0
    }

    private var parentOptions: [(id: String, name: String, color: Color)] {
        var list: [(String, String, Color)] = [("none", "タグなし", tagColor(for: 0))]
        for tag in tags where tag.parentTagID == nil {
            list.append((tag.id.uuidString, tag.name, tagColor(for: tag.colorIndex)))
        }
        list.append(("add", "＋追加", Color.blue.opacity(0.15)))
        return list
    }

    private var childOptions: [(id: String, name: String, color: Color)] {
        var list: [(String, String, Color)] = [("none", "なし", tagColor(for: 0))]
        if let parentID = viewModel.selectedTagID {
            for tag in tags where tag.parentTagID == parentID {
                list.append((tag.id.uuidString, tag.name, tagColor(for: tag.colorIndex)))
            }
        }
        list.append(("add", "＋追加", Color.blue.opacity(0.15)))
        return list
    }

    private var selectedTagInfo: (name: String, color: Color) {
        if let tagID = viewModel.selectedTagID,
           let tag = tags.first(where: { $0.id == tagID }) {
            return (tag.name, tagColor(for: tag.colorIndex))
        }
        return ("タグなし", tagColor(for: 0))
    }

    private var selectedChildTagInfo: (name: String, color: Color)? {
        if let childID = viewModel.selectedChildTagID,
           let tag = tags.first(where: { $0.id == childID }) {
            return (tag.name, tagColor(for: tag.colorIndex))
        }
        return nil
    }

    var body: some View {
        VStack(spacing: 0) {
            // ヘッダー: タイトル + タグ（全モード共通レイアウト）
            headerRow
            Divider()
            // 本文 + ルーレット（最大化ボタンは本文右上にオーバーレイ）
            HStack(spacing: 0) {
                ZStack(alignment: .topTrailing) {
                    contentArea
                    // 最大化ボタン（テキスト入力欄の右上、右端ぴったり）
                    Button {
                        showFullEditor = true
                    } label: {
                        Image(systemName: "viewfinder")
                            .font(.system(size: 14))
                            .foregroundStyle(.gray.opacity(0.5))
                            .padding(5)
                            .background(Circle().fill(Color(uiColor: .systemBackground).opacity(0.9)))
                    }
                    .padding(.trailing, 2)
                    .padding(.top, 2)
                }
                dialArea
            }
            Divider()
            // フッター: 全モード共通（左:削除 右:コピー+保存）
            footerRow
        }
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(uiColor: .systemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.gray.opacity(0.25), lineWidth: 1)
        )
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .alert("このメモを削除します。よろしいですか？", isPresented: $showDeleteAlert) {
            Button("削除", role: .destructive) {
                if mode == .newInput {
                    viewModel.discardMemo(context: modelContext)
                } else if let memo = previewingMemo {
                    modelContext.delete(memo)
                    previewingMemo = nil
                    isEditingExisting = false
                }
            }
            Button("キャンセル", role: .cancel) {}
        }
        .sheet(isPresented: $showNewTagSheet) {
            NewTagSheetView(
                parentTagID: newTagIsChild ? viewModel.selectedTagID : nil,
                onTagCreated: { newTagID in
                    if newTagIsChild {
                        viewModel.selectedChildTagID = newTagID
                    } else {
                        viewModel.selectedTagID = newTagID
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            let idx = tabIndex(for: newTagID)
                            NotificationCenter.default.post(
                                name: .switchToTab, object: nil,
                                userInfo: ["tabIndex": idx]
                            )
                        }
                    }
                }
            )
        }
        .fullScreenCover(isPresented: $showFullEditor) {
            if mode == .newInput {
                FullEditorView(text: $viewModel.inputText, isMarkdown: $viewModel.isMarkdown)
            } else if let memo = previewingMemo {
                MemoDetailView(memo: memo)
            }
        }
        .onChange(of: focusInput) { _, newValue in
            if newValue { isTextEditorFocused = true; focusInput = false }
        }
        .onChange(of: viewModel.inputText) { _, _ in
            if mode == .newInput { viewModel.onContentChanged(context: modelContext, tags: tags) }
        }
        .onChange(of: viewModel.titleText) { _, _ in
            if mode == .newInput { viewModel.onTitleChanged() }
        }
        .onChange(of: viewModel.selectedTagID) { _, newTagID in
            if !viewModel.isLoadingMemo { viewModel.selectedChildTagID = nil }
            if mode == .newInput { viewModel.onTagChanged(tags: tags) }
            if mode == .editing, let memo = previewingMemo {
                memo.tags.removeAll()
                if let tagID = newTagID, let tag = tags.first(where: { $0.id == tagID }) {
                    memo.tags.append(tag)
                }
                if let childID = viewModel.selectedChildTagID,
                   let childTag = tags.first(where: { $0.id == childID }) {
                    memo.tags.append(childTag)
                }
                memo.updatedAt = Date()
            }
            let idx = tabIndex(for: newTagID)
            NotificationCenter.default.post(name: .switchToTab, object: nil, userInfo: ["tabIndex": idx])
        }
        .onChange(of: viewModel.selectedChildTagID) { _, newChildID in
            if mode == .newInput { viewModel.onTagChanged(tags: tags) }
            if mode == .editing, let memo = previewingMemo {
                memo.tags.removeAll(where: { $0.parentTagID != nil })
                if let childID = newChildID,
                   let childTag = tags.first(where: { $0.id == childID }) {
                    memo.tags.append(childTag)
                }
                memo.updatedAt = Date()
            }
        }
        .onChange(of: previewingMemo) { _, newMemo in
            isEditingExisting = false
            if let memo = newMemo {
                editText = memo.content
                editTitle = memo.title
                viewModel.loadMemo(memo)
            }
        }
        .onAppear {
            showParentDial = dialDefault >= 1
            showChildDial = dialDefault >= 2
        }
    }

    // MARK: - ヘッダー行（全モード共通レイアウト）

    private var headerRow: some View {
        HStack(spacing: 6) {
            // タイトル欄 — 常に同じ位置・サイズ
            titleField

            Spacer()

            // 右: タグ表示（タップでルーレット展開）
            tagDisplay
                .onTapGesture {
                    withAnimation(.spring(response: 0.3)) {
                        showParentDial = true
                    }
                }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
    }

    // タイトル欄
    @ViewBuilder
    private var titleField: some View {
        if mode == .newInput {
            TextField("タイトル（任意）", text: $viewModel.titleText)
                .font(.system(size: 15, design: .rounded))
        } else if mode == .editing {
            TextField("タイトル（任意）", text: $editTitle)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
        } else {
            // プレビュー — タイトルがあればText、なければプレースホルダー
            let title = previewingMemo?.title ?? ""
            if title.isEmpty {
                Text("タイトル（任意）")
                    .font(.system(size: 15, design: .rounded))
                    .foregroundStyle(.gray.opacity(0.4))
                    .onTapGesture { enterEditingMode() }
            } else {
                Text(title)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .lineLimit(1)
                    .onTapGesture { enterEditingMode() }
            }
        }
    }

    // タグ表示（ヘッダー右側）
    private var tagDisplay: some View {
        HStack(spacing: 3) {
            let info = selectedTagInfo
            Text(info.name.prefix(4) + (info.name.count > 4 ? "…" : ""))
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(RoundedRectangle(cornerRadius: 5).fill(info.color))
            if let childInfo = selectedChildTagInfo {
                Text(childInfo.name.prefix(3) + (childInfo.name.count > 3 ? "…" : ""))
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(RoundedRectangle(cornerRadius: 4).fill(childInfo.color))
            }
        }
    }

    // プレビュー→編集モードへの移行
    private func enterEditingMode() {
        if let memo = previewingMemo {
            editText = memo.content
            editTitle = memo.title
            viewModel.loadMemo(memo)
            isEditingExisting = true
        }
    }

    // MARK: - コンテンツ（全モード共通の枠内に表示）

    @ViewBuilder
    private var contentArea: some View {
        switch mode {
        case .newInput:
            newInputContent
        case .preview:
            previewContent
        case .editing:
            editingContent
        }
    }

    private var newInputContent: some View {
        ZStack(alignment: .topLeading) {
            TextEditor(text: $viewModel.inputText)
                .font(.system(size: 17))
                .padding(.horizontal, 4)
                .padding(.top, 4)
                .padding(.trailing, 24)
                .focused($isTextEditorFocused)

            if viewModel.inputText.isEmpty {
                Text(viewModel.isMarkdown ? "タップでマークダウン編集..." : "メモを入力...")
                    .font(.system(size: 17))
                    .foregroundStyle(.gray.opacity(0.5))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 12)
                    .allowsHitTesting(false)
            }
        }
        .frame(maxHeight: .infinity)
    }

    private var previewContent: some View {
        ScrollView {
            Text(previewingMemo?.content ?? "（内容なし）")
                .font(.system(size: 17))
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .padding(.trailing, 20)
        }
        .frame(maxHeight: .infinity)
        .contentShape(Rectangle())
        .onTapGesture { enterEditingMode() }
    }

    private var editingContent: some View {
        TextEditor(text: $editText)
            .font(.system(size: 17))
            .padding(.horizontal, 4)
            .padding(.top, 4)
            .padding(.trailing, 24)
            .focused($isTextEditorFocused)
            .frame(maxHeight: .infinity)
            .onChange(of: editText) { _, newValue in
                previewingMemo?.content = newValue
                previewingMemo?.updatedAt = Date()
            }
            .onChange(of: editTitle) { _, newValue in
                previewingMemo?.title = newValue
                previewingMemo?.updatedAt = Date()
            }
    }

    // MARK: - フッター行（全モード共通: 左=削除 右=コピー+保存）

    private var footerRow: some View {
        HStack(spacing: 8) {
            // 左: 削除ボタン
            Button { showDeleteAlert = true } label: {
                Image(systemName: "trash")
                    .font(.system(size: 13))
                    .foregroundStyle(.red.opacity(0.5))
            }
            .disabled(mode == .newInput && !viewModel.canClear)

            Spacer()

            // 右: コピー
            Button {
                UIPasteboard.general.string = currentText
            } label: {
                Label("コピー", systemImage: "doc.on.doc").font(.system(size: 14))
            }
            .disabled(currentText.isEmpty)

            // 右: 保存
            Button { performSave() } label: {
                Label("保存", systemImage: "square.and.arrow.down.fill")
                    .font(.system(size: 14, weight: .bold))
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
            .controlSize(.small)
            .disabled(!canSave)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
    }

    // 保存アクション
    private func performSave() {
        switch mode {
        case .newInput:
            let targetTab = tabIndex(for: viewModel.selectedTagID)
            viewModel.clearInput()
            showParentDial = dialDefault >= 1
            showChildDial = dialDefault >= 2
            NotificationCenter.default.post(
                name: .switchToTab, object: nil,
                userInfo: ["tabIndex": targetTab]
            )
        case .editing:
            // 編集内容はonChangeで既に保存済み、閲覧モードに戻る
            isEditingExisting = false
            isTextEditorFocused = false
        case .preview:
            break
        }
    }

    // MARK: - ルーレット（収納式）

    private var dialArea: some View {
        HStack(spacing: 0) {
            if showParentDial {
                Rectangle().fill(Color.gray.opacity(0.2)).frame(width: 1)

                TagDialView(
                    options: parentOptions,
                    selectedID: $viewModel.selectedTagID,
                    width: showChildDial ? 70 : 90,
                    onAddTap: { newTagIsChild = false; showNewTagSheet = true },
                    externalDragY: .constant(nil)
                )

                ZStack {
                    if showChildDial {
                        HStack(spacing: 0) {
                            Rectangle().fill(Color.gray.opacity(0.2)).frame(width: 1)
                            TagDialView(
                                options: childOptions,
                                selectedID: $viewModel.selectedChildTagID,
                                width: 65,
                                onAddTap: { newTagIsChild = true; showNewTagSheet = true },
                                externalDragY: $childExternalDragY
                            )
                            Text("›")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.secondary)
                                .frame(width: 14, height: 60)
                                .background(RoundedRectangle(cornerRadius: 4).fill(Color.gray.opacity(0.1)))
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    withAnimation(.spring(response: 0.3)) { showChildDial = false }
                                }
                        }
                    } else {
                        VStack(spacing: 2) {
                            Text("子").font(.system(size: 11, weight: .bold, design: .rounded))
                            Text("‹").font(.system(size: 12, weight: .bold))
                        }
                        .foregroundStyle(.secondary)
                        .frame(width: 20, height: 60)
                        .background(RoundedRectangle(cornerRadius: 4).fill(Color.gray.opacity(0.15)))
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3)) { showChildDial = true }
                        }
                    }
                }
                .contentShape(Rectangle())
                .simultaneousGesture(
                    DragGesture(minimumDistance: 5)
                        .onChanged { value in
                            if !showChildDial { showChildDial = true }
                            childExternalDragY = value.translation.height
                        }
                        .onEnded { _ in childExternalDragY = nil }
                )

                Text("›")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.tertiary)
                    .frame(width: 12, height: 50)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3)) {
                            showParentDial = false; showChildDial = false
                        }
                    }
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 10)
                            .onEnded { value in
                                if value.translation.width > 20 {
                                    withAnimation(.spring(response: 0.3)) {
                                        showParentDial = false; showChildDial = false
                                    }
                                }
                            }
                    )
            } else {
                VStack(spacing: 3) {
                    Text("タグ").font(.system(size: 11, weight: .bold, design: .rounded))
                    Text("‹").font(.system(size: 14, weight: .bold))
                }
                .foregroundStyle(.secondary)
                .frame(width: 28, height: 80)
                .background(RoundedRectangle(cornerRadius: 6).fill(Color.gray.opacity(0.12)))
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.spring(response: 0.3)) { showParentDial = true }
                }
                .simultaneousGesture(
                    DragGesture(minimumDistance: 5)
                        .onChanged { _ in
                            if !showParentDial {
                                withAnimation(.spring(response: 0.3)) { showParentDial = true }
                            }
                        }
                )
            }
        }
    }
}
