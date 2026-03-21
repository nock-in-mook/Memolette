import SwiftUI
import SwiftData

// セル内包方式: ルーレット→タグ→タイトル→本文を縦に配置
// 各セルが独立したタグ状態を持ち、親ビューのState変更をゼロにする
struct QuickSortCellView: View {
    let memo: Memo
    let showLeftArrow: Bool
    let showRightArrow: Bool
    var isActive: Bool = false

    // ルーレット領域の高さ（CarouselViewのジェスチャーブロックにも使用）
    static let dialAreaHeight: CGFloat = 250

    // コールバック（親ビューへの通知）
    var onTagChanged: (UUID) -> Void = { _ in }
    var onTitleChanged: (UUID) -> Void = { _ in }
    var onEditBody: () -> Void = {}
    var onDelete: (Memo) -> Void = { _ in }
    var onNewTagSheet: (_ isChild: Bool, _ parentTagID: UUID?) -> Void = { _, _ in }
    var onGoPrev: () -> Void = {}
    var onGoNext: () -> Void = {}

    @Query(sort: \Tag.name) private var tags: [Tag]
    @Environment(\.modelContext) private var modelContext

    // ローカルタグ状態（セル独立 → 親ビューの再描画ゼロ）
    @State private var selectedParentTagID: UUID?
    @State private var selectedChildTagID: UUID?
    @State private var showChildDial = true
    @State private var childExternalDragY: CGFloat?
    @State private var isInternalTagChange = false

    // タイトル編集（インライン）
    @State private var editingTitle: String = ""
    @FocusState private var isTitleFocused: Bool

    // ローカル削除状態
    @State private var deleteOffset: CGFloat = 0
    @State private var isDeletingCard = false

    // ピカピカアニメーション
    @State private var flashTag = false
    @State private var flashTitle = false

    var body: some View {
        VStack(spacing: 0) {
            // 1. ルーレット（常時全開）
            dialArea
                .frame(height: QuickSortCellView.dialAreaHeight, alignment: .top)
                .clipped()

            // 2. タグ欄（ルーレット連動）
            tagRow
                .padding(.horizontal, 20)
                .padding(.top, 6)

            // 3. タイトル欄（タップで直接編集）
            titleRow
                .padding(.horizontal, 20)
                .padding(.top, 6)

            // 4. 本文欄（カード状・タップで編集画面へ）
            bodyCard
                .padding(.horizontal, 20)
                .padding(.top, 6)

            // 5. ナビゲーション（タップで前後移動 + 削除ガイド）
            navRow
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 8)
        }
        .onAppear {
            initFromMemo()
            editingTitle = memo.title
        }
        .onChange(of: memo.tags.map(\.id)) { _, _ in initFromMemo() }
        .onChange(of: memo.id) { _, _ in
            initFromMemo()
            editingTitle = memo.title
            flashTag = false
            flashTitle = false
        }
        .onChange(of: selectedParentTagID) { oldVal, newVal in
            guard !isInternalTagChange else { return }
            if oldVal != newVal { selectedChildTagID = nil }
            applyTagFromDial()
        }
        .onChange(of: selectedChildTagID) { _, _ in
            guard !isInternalTagChange else { return }
            applyTagFromDial()
        }
        .onChange(of: isTitleFocused) { _, focused in
            if !focused { commitTitle() }
        }
        .onChange(of: isActive) { _, active in
            if active { triggerFlash() }
            else { flashTag = false; flashTitle = false }
        }
    }

    // MARK: - 初期化（memo.tagsからローカルStateを設定）

    private func initFromMemo() {
        let parentTag = memo.tags.first(where: { $0.parentTagID == nil })
        let childTag = memo.tags.first(where: { $0.parentTagID != nil })
        let newParentID = parentTag?.id
        let newChildID = childTag?.id
        let needsUpdate = (newParentID != selectedParentTagID) || (newChildID != selectedChildTagID)
        guard needsUpdate else { return }
        isInternalTagChange = true
        selectedParentTagID = newParentID
        selectedChildTagID = newChildID
        if parentTag != nil {
            let hasChildren = tags.contains(where: { $0.parentTagID == parentTag?.id })
            if hasChildren { showChildDial = true }
        }
        DispatchQueue.main.async { isInternalTagChange = false }
    }

    // MARK: - タグ操作（セル内で直接memo.tagsに書き込み）

    private func applyTagFromDial() {
        let originalTags = Set(memo.tags.map { $0.id })
        memo.tags.removeAll()
        if let pid = selectedParentTagID, let tag = tags.first(where: { $0.id == pid }) { memo.tags.append(tag) }
        if let cid = selectedChildTagID, let tag = tags.first(where: { $0.id == cid }) { memo.tags.append(tag) }
        let newTags = Set(memo.tags.map { $0.id })
        if originalTags != newTags {
            memo.updatedAt = Date()
            onTagChanged(memo.id)
        }
    }

    // MARK: - タイトル確定

    private func commitTitle() {
        let newTitle = editingTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        if newTitle != memo.title {
            memo.title = newTitle
            memo.updatedAt = Date()
            if !newTitle.isEmpty { onTitleChanged(memo.id) }
        }
    }

    // MARK: - ピカピカアニメーション

    private func triggerFlash() {
        let noTag = selectedParentTagID == nil
        let noTitle = memo.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

        if noTag {
            flashTag = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.easeInOut(duration: 0.25).repeatCount(5, autoreverses: true)) {
                    flashTag = true
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.7) {
                withAnimation(.easeOut(duration: 0.3)) { flashTag = false }
            }
        }
        if noTitle {
            flashTitle = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.easeInOut(duration: 0.25).repeatCount(5, autoreverses: true)) {
                    flashTitle = true
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.7) {
                withAnimation(.easeOut(duration: 0.3)) { flashTitle = false }
            }
        }
    }

    // MARK: - タグ欄

    private var tagRow: some View {
        HStack(spacing: 6) {
            let parentTag = memo.tags.first(where: { $0.parentTagID == nil })
            let childTag = memo.tags.first(where: { $0.parentTagID != nil })

            if let pt = parentTag {
                // 親タグバッジ
                Text(pt.name)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .lineLimit(1)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(tagColor(for: pt.colorIndex))
                    )

                if let ct = childTag {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.secondary)
                    // 子タグバッジ
                    Text(ct.name)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .lineLimit(1)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(tagColor(for: ct.colorIndex))
                        )
                }
            } else {
                Text("タグなし")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary.opacity(0.5))
            }

            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(flashTag ? Color.orange.opacity(0.15) : Color(uiColor: .secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(flashTag ? Color.orange : Color.clear, lineWidth: 2)
        )
    }

    // MARK: - タイトル欄（タップで直接編集）

    private var titleRow: some View {
        TextField("タイトルなし", text: $editingTitle)
            .font(.system(size: 20, weight: .bold, design: .rounded))
            .focused($isTitleFocused)
            .onSubmit { isTitleFocused = false }
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(flashTitle ? Color.orange.opacity(0.15) : Color(uiColor: .secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(flashTitle ? Color.orange : Color.clear, lineWidth: 2)
            )
    }

    // MARK: - 本文欄（カード状・タップで編集画面へ）

    private var bodyCard: some View {
        let displayText = memo.content.isEmpty
            ? "（本文なし）"
            : String(memo.content.prefix(200))

        return Text(displayText)
            .font(.system(size: 16))
            .foregroundColor(memo.content.isEmpty ? Color.secondary.opacity(0.4) : Color.primary)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(12)
            .background(Color(uiColor: .systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.secondary.opacity(0.15), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
            .contentShape(Rectangle())
            .onTapGesture {
                commitTitle()
                isTitleFocused = false
                onEditBody()
            }
            .offset(y: isDeletingCard ? deleteOffset : 0)
            .opacity(isDeletingCard ? max(0.0, 1.0 - Double(deleteOffset) / 300.0) : 1.0)
            .simultaneousGesture(
                DragGesture(minimumDistance: 20)
                    .onChanged { value in
                        let t = value.translation
                        if t.height > 15 && abs(t.height) > abs(t.width) * 1.5 {
                            isDeletingCard = true
                            deleteOffset = t.height
                        }
                    }
                    .onEnded { value in
                        guard isDeletingCard else { return }
                        if value.translation.height > 100 {
                            withAnimation(.easeOut(duration: 0.2)) { deleteOffset = 500 }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                onDelete(memo)
                                isDeletingCard = false
                                deleteOffset = 0
                            }
                        } else {
                            withAnimation(.spring(response: 0.3)) { deleteOffset = 0 }
                            isDeletingCard = false
                        }
                    }
            )
    }

    // MARK: - ナビゲーション（タップで前後 + 削除ガイド）

    private var navRow: some View {
        HStack(spacing: 0) {
            // ◁ タップで前へ
            Button {
                commitTitle()
                isTitleFocused = false
                onGoPrev()
            } label: {
                HStack(spacing: 4) {
                    Triangle()
                        .fill(showLeftArrow ? Color.blue.opacity(0.6) : Color.clear)
                        .frame(width: 12, height: 18)
                        .rotationEffect(.degrees(-90))
                    Text("タップで前へ")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(showLeftArrow ? .blue.opacity(0.7) : .clear)
                }
            }
            .disabled(!showLeftArrow)
            .buttonStyle(.plain)

            Spacer()

            // ↓ 下にスワイプで削除
            VStack(spacing: 1) {
                Image(systemName: "arrow.down")
                    .font(.system(size: 14, weight: .bold))
                Text("下スワイプで削除")
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundStyle(.red.opacity(0.35))

            Spacer()

            // ▷ タップで次へ
            Button {
                commitTitle()
                isTitleFocused = false
                onGoNext()
            } label: {
                HStack(spacing: 4) {
                    Text("タップで次へ")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(showRightArrow ? .blue.opacity(0.7) : .clear)
                    Triangle()
                        .fill(showRightArrow ? Color.blue.opacity(0.6) : Color.clear)
                        .frame(width: 12, height: 18)
                        .rotationEffect(.degrees(90))
                }
            }
            .disabled(!showRightArrow)
            .buttonStyle(.plain)
        }
    }

    // MARK: - ルーレットエリア

    private var parentOptions: [(id: String, name: String, color: Color)] {
        let parentTags = tags.filter { $0.parentTagID == nil }.sorted { $0.sortOrder < $1.sortOrder }
        return [("none", "タグなし", Color(white: 0.82))] +
            parentTags.map { ($0.id.uuidString, $0.name, tagColor(for: $0.colorIndex)) }
    }

    private var childOptions: [(id: String, name: String, color: Color)] {
        let childTags: [Tag] = {
            guard let pid = selectedParentTagID else { return [] }
            return tags.filter { $0.parentTagID == pid }.sorted { $0.name < $1.name }
        }()
        return [("none", "子タグなし", Color(white: 0.82))] +
            childTags.map { ($0.id.uuidString, $0.name, tagColor(for: $0.colorIndex)) }
    }

    private var dialArea: some View {
        VStack(spacing: 0) {
            // ラベル（親タグ・子タグ）
            ZStack(alignment: .trailing) {
                Text("親タグ")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary.opacity(0.5))
                    .padding(.trailing, 165)
                Text("子タグ")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary.opacity(0.5))
                    .padding(.trailing, 50)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            .frame(height: 14)

            // ルーレット本体
            TagDialView(
                parentOptions: parentOptions,
                parentSelectedID: $selectedParentTagID,
                childOptions: childOptions,
                childSelectedID: $selectedChildTagID,
                showChild: $showChildDial,
                isOpen: true,
                childExternalDragY: $childExternalDragY,
                onLongPress: nil
            )
            .frame(height: 211)

            // 追加ボタン
            HStack(spacing: 12) {
                Spacer()
                Button {
                    onNewTagSheet(false, nil)
                } label: {
                    Label("親タグ追加", systemImage: "plus.circle.fill")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary.opacity(0.6))
                }
                Button {
                    if selectedParentTagID != nil {
                        onNewTagSheet(true, selectedParentTagID)
                    }
                } label: {
                    Label("子タグ追加", systemImage: "plus.circle")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary.opacity(selectedParentTagID == nil ? 0.25 : 0.5))
                }
            }
            .padding(.trailing, 8)
            .offset(y: -8)
        }
    }
}
