import SwiftUI
import SwiftData

struct TagTitleSheetView: View {
    @Bindable var memo: Memo
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Tag.name) private var existingTags: [Tag]
    @State private var titleText: String = ""
    @State private var selectedTagIDs: Set<UUID> = []
    @State private var newTagName: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("タイトル（任意）") {
                    TextField("タイトルを入力", text: $titleText)
                }

                Section("タグを選択（任意）") {
                    // 既存タグの選択
                    ForEach(existingTags) { tag in
                        Button {
                            toggleTag(tag)
                        } label: {
                            HStack {
                                Text(tag.name)
                                Spacer()
                                if selectedTagIDs.contains(tag.id) {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                        .foregroundStyle(.primary)
                    }

                    // 新規タグ追加
                    HStack {
                        TextField("新しいタグ", text: $newTagName)
                        Button {
                            addNewTag()
                        } label: {
                            Image(systemName: "plus.circle.fill")
                        }
                        .disabled(newTagName.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
            }
            .navigationTitle("メモの設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("スキップ") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("決定") {
                        applySettings()
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func toggleTag(_ tag: Tag) {
        if selectedTagIDs.contains(tag.id) {
            selectedTagIDs.remove(tag.id)
        } else {
            selectedTagIDs.insert(tag.id)
        }
    }

    private func addNewTag() {
        let name = newTagName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        let tag = Tag(name: name)
        modelContext.insert(tag)
        selectedTagIDs.insert(tag.id)
        newTagName = ""
    }

    private func applySettings() {
        if !titleText.isEmpty {
            memo.title = titleText
        }
        // 選択されたタグをメモに紐付け
        // existingTagsに加え、新規作成タグも含める
        let allTags = existingTags
        memo.tags = allTags.filter { selectedTagIDs.contains($0.id) }
        memo.updatedAt = Date()
    }
}
