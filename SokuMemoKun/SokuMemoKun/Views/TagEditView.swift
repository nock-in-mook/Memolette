import SwiftUI
import SwiftData

// タグ編集画面（一覧・色変更・名前変更・削除）
struct TagEditView: View {
    @Query(sort: \Tag.name) private var tags: [Tag]
    @Environment(\.modelContext) private var modelContext
    @State private var editingTag: Tag?
    @State private var showNewTagSheet = false

    var body: some View {
        List {
            ForEach(tags) { tag in
                Button {
                    editingTag = tag
                } label: {
                    HStack(spacing: 10) {
                        // カラーインジケータ
                        RoundedRectangle(cornerRadius: 4)
                            .fill(tagColor(for: tag.colorIndex))
                            .frame(width: 24, height: 24)

                        // タグ名
                        Text(tag.name)
                            .font(.system(size: 15, design: .rounded))
                            .foregroundStyle(.primary)

                        Spacer()

                        // メモ数
                        Text("\(tag.memos.count)件")
                            .font(.system(size: 12, design: .rounded))
                            .foregroundStyle(.tertiary)

                        Image(systemName: "chevron.right")
                            .font(.system(size: 12))
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            .onDelete(perform: deleteTags)
        }
        .navigationTitle("タグ編集")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showNewTagSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(item: $editingTag) { tag in
            TagDetailEditView(tag: tag)
        }
        .sheet(isPresented: $showNewTagSheet) {
            NewTagSheetView()
        }
    }

    private func deleteTags(at offsets: IndexSet) {
        for index in offsets {
            let tag = tags[index]
            // タグを削除（メモからの参照も自動解除）
            for memo in tag.memos {
                memo.tags.removeAll { $0.id == tag.id }
            }
            modelContext.delete(tag)
        }
    }
}

// 個別タグ編集シート（名前変更・色変更）
struct TagDetailEditView: View {
    @Bindable var tag: Tag
    @Environment(\.dismiss) private var dismiss

    @State private var editName: String = ""
    @State private var editColorIndex: Int = 1

    private let colorOptions: [(index: Int, label: String)] = [
        (1, "水色"), (2, "オレンジ"), (3, "緑"), (4, "紫"),
        (5, "黄色"), (6, "赤"), (7, "青")
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // タグ名入力
                VStack(alignment: .leading, spacing: 6) {
                    Text("タグ名")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)

                    TextField("タグ名を入力（20文字まで）", text: $editName)
                        .font(.system(size: 16, design: .rounded))
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(uiColor: .secondarySystemBackground))
                        )
                        .onChange(of: editName) { _, newValue in
                            if newValue.count > 20 {
                                editName = String(newValue.prefix(20))
                            }
                        }

                    Text("\(editName.count)/20")
                        .font(.system(size: 11, design: .rounded))
                        .foregroundStyle(.tertiary)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }

                // カラー選択
                VStack(alignment: .leading, spacing: 6) {
                    Text("カラー")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 4), spacing: 10) {
                        ForEach(colorOptions, id: \.index) { option in
                            Button {
                                editColorIndex = option.index
                            } label: {
                                VStack(spacing: 4) {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(tagColor(for: option.index))
                                        .frame(height: 40)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(
                                                    editColorIndex == option.index
                                                        ? Color.primary : Color.clear,
                                                    lineWidth: 2.5
                                                )
                                        )

                                    Text(option.label)
                                        .font(.system(size: 10, design: .rounded))
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }

                // プレビュー
                VStack(alignment: .leading, spacing: 6) {
                    Text("プレビュー")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)

                    HStack {
                        Text("タグ:")
                            .font(.system(size: 10, design: .rounded))
                            .foregroundStyle(.secondary)

                        Text(previewName)
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(.primary.opacity(0.8))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(tagColor(for: editColorIndex))
                            )
                    }
                }

                Spacer()
            }
            .padding(20)
            .navigationTitle("タグを編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        saveChanges()
                    }
                    .disabled(editName.trimmingCharacters(in: .whitespaces).isEmpty)
                    .bold()
                }
            }
            .onAppear {
                editName = tag.name
                editColorIndex = tag.colorIndex
            }
        }
        .presentationDetents([.medium])
    }

    private var previewName: String {
        let name = editName.isEmpty ? "サンプル" : editName
        if name.count > 5 {
            return String(name.prefix(5)) + "…"
        }
        return name
    }

    private func saveChanges() {
        let trimmed = editName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        tag.name = trimmed
        tag.colorIndex = editColorIndex
        dismiss()
    }
}
