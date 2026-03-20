import SwiftUI
import SwiftData
import os

private let logger = Logger(subsystem: "com.sokumemokun.app", category: "QuickSort")

// 爆速振り分けモード: メインカード画面
struct QuickSortView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Tag.name) private var tags: [Tag]

    // 対象メモ（フィルタ済み）
    let targetMemos: [Memo]
    var onDismiss: () -> Void

    // タグサジェストエンジン
    @State private var suggestEngine = TagSuggestEngine()

    // 現在のインデックス
    @State private var currentIndex = 0

    // カードのドラッグ状態
    @State private var dragOffset: CGSize = .zero
    @State private var isDragging = false

    // ルーレット状態（子タグ表示がデフォルト）
    @State private var selectedParentTagID: UUID? = nil
    @State private var selectedChildTagID: UUID? = nil
    @State private var showChildDial = true
    @State private var childExternalDragY: CGFloat? = nil
    // ルーレット変更の内部フラグ（無限ループ防止）
    @State private var isInternalTagChange = false

    // 編集状態
    @State private var editingTitle = ""
    @State private var editingContent = ""
    @State private var isEditingTitle = false
    @State private var isEditingContent = false

    // サジェスト
    @State private var currentSuggestions: [TagSuggestEngine.Suggestion] = []
    @State private var suggestCache: [Int: [TagSuggestEngine.Suggestion]] = [:]

    // 変更ログ
    @State private var taggedMemoIDs: Set<UUID> = []
    @State private var titledMemoIDs: Set<UUID> = []
    @State private var editedMemoIDs: Set<UUID> = []
    // 削除予定キュー（完了時に一括削除）
    @State private var deleteQueue: [Memo] = []
    @State private var skippedIndices: Set<Int> = []

    // 戦績表示
    @State private var showResult = false
    @State private var showDeleteReview = false

    // 現在のメモ
    private var currentMemo: Memo? {
        guard currentIndex >= 0 && currentIndex < targetMemos.count else { return nil }
        return skippedIndices.contains(currentIndex) ? nil : targetMemos[currentIndex]
    }

    private var activeCount: Int {
        targetMemos.count - skippedIndices.count
    }

    private var displayNumber: Int {
        guard !targetMemos.isEmpty else { return 0 }
        var count = 0
        for i in 0...min(currentIndex, targetMemos.count - 1) {
            if !skippedIndices.contains(i) { count += 1 }
        }
        return count
    }

    // ドラッグ方向の判定
    private var isDraggingUp: Bool { isDragging && dragOffset.height < -30 }
    private var isDraggingLeft: Bool { isDragging && dragOffset.width < -30 && abs(dragOffset.height) < 50 }
    private var isDraggingRight: Bool { isDragging && dragOffset.width > 30 && abs(dragOffset.height) < 50 }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color(uiColor: .systemGroupedBackground).ignoresSafeArea()

                if let memo = currentMemo {
                    mainContent(memo: memo, geo: geo)
                } else if targetMemos.isEmpty || activeCount == 0 {
                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(.green)
                        Text("対象のメモがありません")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Color.clear.onAppear { moveToNextActive() }
                }

                // 戦績オーバーレイ
                if showResult {
                    QuickSortResultView(
                        taggedCount: taggedMemoIDs.count,
                        titledCount: titledMemoIDs.count,
                        editedCount: editedMemoIDs.count,
                        deletedCount: deleteQueue.count,
                        deletedMemos: deleteQueue,
                        onReviewDeleted: {
                            showResult = false
                            showDeleteReview = true
                        },
                        onClose: {
                            for memo in deleteQueue { modelContext.delete(memo) }
                            try? modelContext.save()
                            onDismiss()
                        }
                    )
                }
            }
        }
        .sheet(isPresented: $showDeleteReview) { deleteReviewSheet }
        .onAppear {
            logger.warning("onAppear: targetMemos.count = \(self.targetMemos.count)")
            loadCurrentMemo()
            prefetchSuggestions()
        }
        // ルーレット回したら即タグ反映
        .onChange(of: selectedParentTagID) { _, _ in
            if !isInternalTagChange { applyTagFromDial() }
        }
        .onChange(of: selectedChildTagID) { _, _ in
            if !isInternalTagChange { applyTagFromDial() }
        }
    }

    // MARK: - メインコンテンツ

    @ViewBuilder
    private func mainContent(memo: Memo, geo: GeometryProxy) -> some View {
        VStack(spacing: 0) {
            // ナビバー
            navBar
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 4)

            // 削除ゾーン（上部）
            deleteZone
                .frame(height: 44)

            // タイトル（編集可能）
            titleArea
                .padding(.horizontal, 16)
                .padding(.vertical, 4)

            // 本文カード（スワイプ対象・上部約35%）
            bodyCard(memo: memo)
                .frame(height: geo.size.height * 0.30)
                .padding(.horizontal, 16)

            // 左右ナビゲーションインジケーター
            swipeIndicators

            // 現在のタグ表示（本文の下、ルーレットの上）
            currentTagsBar(memo: memo)
                .padding(.horizontal, 16)
                .padding(.top, 6)

            // 下部: サジェスト（左）+ ルーレット（右）
            HStack(alignment: .top, spacing: 0) {
                // 左: サジェストパネル
                suggestPanel
                    .frame(maxWidth: .infinity, alignment: .leading)

                // 右: ルーレット
                dialArea
            }
            .padding(.top, 4)

            Spacer(minLength: 0)
        }
    }

    // MARK: - ナビバー

    private var navBar: some View {
        HStack {
            // 閉じる
            Button {
                saveCurrent()
                onDismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // カウンター
            if activeCount > 0 {
                Text("\(displayNumber) / \(activeCount)")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // 完了ボタン
            Button {
                saveCurrent()
                withAnimation(.easeOut(duration: 0.25)) { showResult = true }
            } label: {
                Text("完了")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(Color.orange))
            }
        }
    }

    // MARK: - 削除ゾーン

    private var deleteZone: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(isDraggingUp ? Color.red.opacity(0.2) : Color.red.opacity(0.05))
                .animation(.easeOut(duration: 0.15), value: isDraggingUp)

            HStack(spacing: 6) {
                Image(systemName: "arrow.up")
                    .font(.system(size: isDraggingUp ? 22 : 16, weight: .bold))
                Text("削除")
                    .font(.system(size: isDraggingUp ? 18 : 14, weight: .bold, design: .rounded))
            }
            .foregroundStyle(isDraggingUp ? .red : .red.opacity(0.3))
            .animation(.easeOut(duration: 0.15), value: isDraggingUp)
        }
        .padding(.horizontal, 16)
    }

    // MARK: - タイトル

    private var titleArea: some View {
        Group {
            if isEditingTitle {
                TextField("タイトルを入力", text: $editingTitle)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .onSubmit {
                        isEditingTitle = false
                        applyTitleEdit()
                    }
            } else {
                HStack {
                    Text(editingTitle.isEmpty ? "タイトルなし" : editingTitle)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(editingTitle.isEmpty ? Color.secondary.opacity(0.4) : Color.primary)
                        .lineLimit(1)
                    Spacer()
                    Image(systemName: "pencil")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary.opacity(0.4))
                }
                .contentShape(Rectangle())
                .onTapGesture { isEditingTitle = true }
            }
        }
    }

    // MARK: - 本文カード（スワイプ対象）

    @ViewBuilder
    private func bodyCard(memo: Memo) -> some View {
        ZStack {
            // カード本体
            VStack(spacing: 0) {
                if isEditingContent {
                    TextEditor(text: $editingContent)
                        .font(.system(size: 14))
                        .scrollContentBackground(.hidden)
                        .padding(8)
                        .toolbar {
                            ToolbarItemGroup(placement: .keyboard) {
                                Spacer()
                                Button("完了") {
                                    isEditingContent = false
                                    applyContentEdit()
                                    UIApplication.shared.sendAction(
                                        #selector(UIResponder.resignFirstResponder),
                                        to: nil, from: nil, for: nil
                                    )
                                }
                            }
                        }
                } else {
                    ScrollView {
                        Text(editingContent.isEmpty ? "（本文なし）" : editingContent)
                            .font(.system(size: 14))
                            .foregroundColor(editingContent.isEmpty ? Color.secondary.opacity(0.4) : Color.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(12)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { isEditingContent = true }
                }
            }
            .background(Color(uiColor: .systemBackground))
            .cornerRadius(14)
            .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
        }
        .offset(dragOffset)
        .opacity(isDraggingUp ? max(0.3, 1.0 + Double(dragOffset.height) / 300.0) : 1.0)
        .rotationEffect(.degrees(Double(dragOffset.width) / 30.0))
        .gesture(
            DragGesture()
                .onChanged { value in
                    isDragging = true
                    let t = value.translation
                    if t.height < -20 && abs(t.width) < abs(t.height) {
                        // 上ドラッグ → 削除
                        dragOffset = CGSize(width: t.width * 0.3, height: t.height)
                    } else if abs(t.width) > 20 {
                        // 左右ドラッグ → 移動
                        dragOffset = CGSize(width: t.width, height: t.height * 0.2)
                    } else {
                        dragOffset = t
                    }
                }
                .onEnded { value in
                    isDragging = false
                    let t = value.translation
                    if t.height < -120 {
                        // 上フリック → 削除
                        withAnimation(.easeOut(duration: 0.2)) {
                            dragOffset = CGSize(width: 0, height: -600)
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            deleteCurrentMemo()
                        }
                    } else if t.width < -100 {
                        // 左フリック → 次へ
                        withAnimation(.easeOut(duration: 0.15)) {
                            dragOffset = CGSize(width: -400, height: 0)
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                            saveCurrent()
                            moveToNextActive()
                        }
                    } else if t.width > 100 {
                        // 右フリック → 前へ
                        withAnimation(.easeOut(duration: 0.15)) {
                            dragOffset = CGSize(width: 400, height: 0)
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                            saveCurrent()
                            moveToPreviousActive()
                        }
                    } else {
                        withAnimation(.spring(response: 0.3)) { dragOffset = .zero }
                    }
                }
        )
    }

    // MARK: - スワイプインジケーター

    private var swipeIndicators: some View {
        HStack {
            // 左: 前へ
            HStack(spacing: 4) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 12, weight: .bold))
                Text("前へ")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
            }
            .foregroundStyle(isDraggingRight ? .blue : .secondary.opacity(0.25))
            .animation(.easeOut(duration: 0.15), value: isDraggingRight)

            Spacer()

            // 右: 次へ
            HStack(spacing: 4) {
                Text("次へ")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
            }
            .foregroundStyle(isDraggingLeft ? .blue : .secondary.opacity(0.25))
            .animation(.easeOut(duration: 0.15), value: isDraggingLeft)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 2)
    }

    // MARK: - 現在のタグ表示

    @ViewBuilder
    private func currentTagsBar(memo: Memo) -> some View {
        HStack(spacing: 6) {
            ForEach(memo.tags, id: \.id) { tag in
                HStack(spacing: 4) {
                    Circle()
                        .fill(tagColor(for: tag.colorIndex))
                        .frame(width: 8, height: 8)
                    Text(tag.name)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Capsule().fill(tagColor(for: tag.colorIndex).opacity(0.15)))
            }
            if memo.tags.isEmpty {
                Text("タグなし")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary.opacity(0.4))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.gray.opacity(0.1)))
            }
            Spacer()
        }
    }

    // MARK: - サジェストパネル（縦並び・MainViewと同じスタイル）

    private var suggestPanel: some View {
        VStack(alignment: .leading, spacing: 4) {
            if !currentSuggestions.isEmpty {
                // セクション分類
                let dictSugs = currentSuggestions.filter { $0.kind == .dictMatch }
                let newSugs = currentSuggestions.filter { $0.kind == .newTag }
                let histSugs = currentSuggestions.filter { $0.kind == .history }

                Text("タグの提案")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .padding(.leading, 4)

                if !dictSugs.isEmpty {
                    suggestSection(title: "おすすめ", icon: "tag.fill", items: dictSugs)
                }
                if !newSugs.isEmpty {
                    suggestSection(title: "新規タグ", icon: "plus.circle.fill", items: newSugs)
                }
                if !histSugs.isEmpty {
                    suggestSection(title: "履歴", icon: "clock.fill", items: histSugs)
                }
            }
        }
        .padding(.leading, 12)
        .padding(.trailing, 4)
    }

    @ViewBuilder
    private func suggestSection(title: String, icon: String, items: [TagSuggestEngine.Suggestion]) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
                Text(title)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            ForEach(items) { suggestion in
                Button { applySuggestion(suggestion) } label: {
                    HStack(spacing: 4) {
                        if suggestion.kind == .newTag {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(.green)
                        } else if let pt = tags.first(where: { $0.id == suggestion.parentID }) {
                            Circle()
                                .fill(tagColor(for: pt.colorIndex))
                                .frame(width: 8, height: 8)
                        }
                        Text(suggestion.parentName)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.primary)
                        if let cn = suggestion.childName {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 8))
                                .foregroundStyle(.tertiary)
                            Text(cn)
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        (suggestion.kind == .newTag ? Color.green.opacity(0.08) : Color(uiColor: .systemBackground).opacity(0.95))
                    )
                    .cornerRadius(8)
                    .shadow(color: .black.opacity(0.06), radius: 2, y: 1)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - ルーレット（右下、子タグ表示デフォ、適用ボタンなし）

    private var dialArea: some View {
        let parentTags = tags.filter { $0.parentTagID == nil }.sorted { $0.sortOrder < $1.sortOrder }
        let childTags: [Tag] = {
            guard let pid = selectedParentTagID else { return [] }
            return tags.filter { $0.parentTagID == pid }.sorted { $0.name < $1.name }
        }()

        let parentOptions: [(id: String, name: String, color: Color)] =
            [("none", "タグなし", Color(white: 0.82))] +
            parentTags.map { ($0.id.uuidString, $0.name, tagColor(for: $0.colorIndex)) }

        let childOptions: [(id: String, name: String, color: Color)] =
            childTags.isEmpty ? [] :
            [("none", "子タグなし", Color(white: 0.82))] +
            childTags.map { ($0.id.uuidString, $0.name, tagColor(for: $0.colorIndex)) }

        return TagDialView(
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
    }

    // MARK: - 削除確認シート

    private var deleteReviewSheet: some View {
        NavigationStack {
            List {
                ForEach(deleteQueue, id: \.id) { memo in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(memo.title.isEmpty ? "（タイトルなし）" : memo.title)
                            .font(.system(size: 15, weight: .semibold))
                        Text(String(memo.content.prefix(100)))
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                    .swipeActions(edge: .trailing) {
                        Button("復元") {
                            if let idx = deleteQueue.firstIndex(where: { $0.id == memo.id }) {
                                let restored = deleteQueue.remove(at: idx)
                                if let origIdx = targetMemos.firstIndex(where: { $0.id == restored.id }) {
                                    skippedIndices.remove(origIdx)
                                }
                            }
                        }
                        .tint(.green)
                    }
                }
            }
            .navigationTitle("削除予定のメモ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("戻る") {
                        showDeleteReview = false
                        showResult = true
                    }
                }
            }
        }
    }

    // MARK: - アクション

    private func saveCurrent() {
        guard let memo = currentMemo else { return }
        let origTitle = memo.title
        let origContent = memo.content

        memo.title = editingTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        memo.content = editingContent

        if memo.title != origTitle && !memo.title.isEmpty { titledMemoIDs.insert(memo.id) }
        if memo.content != origContent { editedMemoIDs.insert(memo.id) }
        memo.updatedAt = Date()
        isEditingTitle = false
        isEditingContent = false
    }

    private func deleteCurrentMemo() {
        guard let memo = currentMemo else { return }
        deleteQueue.append(memo)
        skippedIndices.insert(currentIndex)
        dragOffset = .zero
        isDragging = false

        if activeCount > 0 {
            moveToNextActive()
        } else {
            withAnimation(.easeOut(duration: 0.25)) { showResult = true }
        }
    }

    // ルーレット回したら即タグ反映
    private func applyTagFromDial() {
        guard let memo = currentMemo else { return }
        let originalTags = Set(memo.tags.map { $0.id })

        memo.tags.removeAll()
        if let pid = selectedParentTagID, let tag = tags.first(where: { $0.id == pid }) {
            memo.tags.append(tag)
        }
        if let cid = selectedChildTagID, let tag = tags.first(where: { $0.id == cid }) {
            memo.tags.append(tag)
        }
        memo.updatedAt = Date()

        let newTags = Set(memo.tags.map { $0.id })
        if originalTags != newTags {
            taggedMemoIDs.insert(memo.id)
            let tagIDs = memo.tags.map { $0.id }
            suggestEngine.learn(title: memo.title, body: memo.content, tagIDs: tagIDs, context: modelContext)
        }
    }

    private func applySuggestion(_ suggestion: TagSuggestEngine.Suggestion) {
        if suggestion.kind == .newTag { return }

        isInternalTagChange = true
        selectedParentTagID = suggestion.parentID
        selectedChildTagID = suggestion.childID
        isInternalTagChange = false

        applyTagFromDial()

        // 次へ自動移動
        saveCurrent()
        moveToNextActive()
    }

    private func applyTitleEdit() {
        guard let memo = currentMemo else { return }
        let newTitle = editingTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        if newTitle != memo.title {
            memo.title = newTitle
            memo.updatedAt = Date()
            if !newTitle.isEmpty { titledMemoIDs.insert(memo.id) }
        }
    }

    private func applyContentEdit() {
        guard let memo = currentMemo else { return }
        if editingContent != memo.content {
            memo.content = editingContent
            memo.updatedAt = Date()
            editedMemoIDs.insert(memo.id)
        }
    }

    // MARK: - ナビゲーション

    private func loadCurrentMemo() {
        guard let memo = currentMemo else { return }
        editingTitle = memo.title
        editingContent = memo.content
        isEditingTitle = false
        isEditingContent = false

        // タグをルーレットに反映（内部変更フラグで即適用を防止）
        isInternalTagChange = true
        let parentTag = memo.tags.first(where: { $0.parentTagID == nil })
        let childTag = memo.tags.first(where: { $0.parentTagID != nil })
        selectedParentTagID = parentTag?.id
        selectedChildTagID = childTag?.id
        if childTag != nil { showChildDial = true }
        isInternalTagChange = false

        // カードリセット
        dragOffset = .zero
        isDragging = false

        updateSuggestions()
    }

    private func moveToNextActive() {
        var next = currentIndex + 1
        while next < targetMemos.count && skippedIndices.contains(next) { next += 1 }
        if next < targetMemos.count {
            currentIndex = next
            loadCurrentMemo()
            prefetchSuggestions()
        } else {
            // 先頭に戻る
            var first = 0
            while first < currentIndex && skippedIndices.contains(first) { first += 1 }
            if first < currentIndex && !skippedIndices.contains(first) {
                currentIndex = first
                loadCurrentMemo()
                prefetchSuggestions()
            }
        }
    }

    private func moveToPreviousActive() {
        var prev = currentIndex - 1
        while prev >= 0 && skippedIndices.contains(prev) { prev -= 1 }
        if prev >= 0 {
            currentIndex = prev
            loadCurrentMemo()
        }
    }

    // MARK: - サジェスト

    private func updateSuggestions() {
        if let cached = suggestCache[currentIndex] {
            currentSuggestions = cached
            return
        }
        guard let memo = currentMemo else { currentSuggestions = []; return }
        let result = suggestEngine.suggest(title: memo.title, body: memo.content, tags: tags, context: modelContext, limit: 3)
        currentSuggestions = result
        suggestCache[currentIndex] = result
    }

    private func prefetchSuggestions() {
        guard !targetMemos.isEmpty else { return }
        let lo = max(0, currentIndex - 1)
        let hi = min(targetMemos.count - 1, currentIndex + 2)
        for i in lo...hi {
            if suggestCache[i] == nil && !skippedIndices.contains(i) {
                let m = targetMemos[i]
                suggestCache[i] = suggestEngine.suggest(title: m.title, body: m.content, tags: tags, context: modelContext, limit: 3)
            }
        }
    }
}
