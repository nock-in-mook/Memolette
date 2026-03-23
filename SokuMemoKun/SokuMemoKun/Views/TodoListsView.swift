import SwiftUI
import SwiftData

// ToDoリスト一覧画面
struct TodoListsView: View {
    let onDismiss: () -> Void
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TodoList.updatedAt, order: .reverse) private var todoLists: [TodoList]

    // 新規リスト作成ダイアログ
    @State private var showNewListDialog = false
    @State private var newListTitle = ""
    @FocusState private var isNewListTitleFocused: Bool

    // 選択中のリスト（編集画面へ遷移）
    @State private var selectedList: TodoList?

    var body: some View {
        NavigationStack {
            Group {
                if todoLists.isEmpty {
                    // リストが空のとき
                    emptyView
                } else {
                    // リスト一覧
                    listView
                }
            }
            .navigationTitle("ToDoリスト")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("閉じる") {
                        onDismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showNewListDialog = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .alert("新しいリスト", isPresented: $showNewListDialog) {
                TextField("リストのタイトル", text: $newListTitle)
                Button("作成") {
                    createList()
                }
                Button("キャンセル", role: .cancel) {
                    newListTitle = ""
                }
            } message: {
                Text("リストのタイトルを入力してください")
            }
            .fullScreenCover(item: $selectedList) { list in
                TodoListView(todoList: list) {
                    selectedList = nil
                }
            }
        }
    }

    // MARK: - 空のとき
    private var emptyView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "checklist")
                .font(.system(size: 48))
                .foregroundStyle(.secondary.opacity(0.4))

            Text("ToDoリストはまだありません")
                .font(.system(size: 17))
                .foregroundStyle(.secondary)

            Button {
                showNewListDialog = true
            } label: {
                Label("リストを作成", systemImage: "plus")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.blue)
                    )
            }

            Spacer()
            Spacer()
        }
    }

    // MARK: - リスト一覧
    private var listView: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(todoLists) { list in
                    listCard(list)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
        }
    }

    // MARK: - リストカード
    @ViewBuilder
    private func listCard(_ list: TodoList) -> some View {
        Button {
            selectedList = list
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "checklist")
                    .font(.system(size: 20))
                    .foregroundStyle(.blue)

                VStack(alignment: .leading, spacing: 2) {
                    Text(list.title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.primary)

                    Text(itemSummary(for: list))
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary.opacity(0.4))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(UIColor.secondarySystemBackground))
            )
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(role: .destructive) {
                deleteList(list)
            } label: {
                Label("削除", systemImage: "trash")
            }
        }
    }

    // MARK: - リスト内の項目サマリ
    private func itemSummary(for list: TodoList) -> String {
        // @Queryでは動的フィルタできないので、modelContextで取得
        let listID = list.id
        let descriptor = FetchDescriptor<TodoItem>(
            predicate: #Predicate { $0.listID == listID }
        )
        let items = (try? modelContext.fetch(descriptor)) ?? []
        let total = items.count
        let done = items.filter(\.isDone).count
        if total == 0 {
            return "項目なし"
        }
        return "\(done)/\(total) 完了"
    }

    // MARK: - リスト作成
    private func createList() {
        let trimmed = newListTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let list = TodoList(title: trimmed)
        modelContext.insert(list)
        try? modelContext.save()
        newListTitle = ""
        // 作成後すぐに開く
        selectedList = list
    }

    // MARK: - リスト削除（中の項目も削除）
    private func deleteList(_ list: TodoList) {
        let listID = list.id
        let descriptor = FetchDescriptor<TodoItem>(
            predicate: #Predicate { $0.listID == listID }
        )
        if let items = try? modelContext.fetch(descriptor) {
            for item in items {
                modelContext.delete(item)
            }
        }
        modelContext.delete(list)
        try? modelContext.save()
    }
}
