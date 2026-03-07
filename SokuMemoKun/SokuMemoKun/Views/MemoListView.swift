import SwiftUI
import SwiftData

struct MemoListView: View {
    let selectedTag: Tag?
    @Query(sort: \Memo.createdAt, order: .reverse) private var allMemos: [Memo]
    @Environment(\.modelContext) private var modelContext

    // 選択中のタグでフィルタ
    private var filteredMemos: [Memo] {
        guard let tag = selectedTag else { return allMemos }
        return allMemos.filter { memo in
            memo.tags.contains { $0.id == tag.id }
        }
    }

    var body: some View {
        List {
            ForEach(filteredMemos) { memo in
                MemoRowView(memo: memo)
            }
            .onDelete { indexSet in
                for index in indexSet {
                    modelContext.delete(filteredMemos[index])
                }
            }
        }
        .listStyle(.plain)
        .overlay {
            if filteredMemos.isEmpty {
                ContentUnavailableView(
                    "メモがありません",
                    systemImage: "note.text",
                    description: Text("上の入力欄からメモを保存しましょう")
                )
            }
        }
    }
}
