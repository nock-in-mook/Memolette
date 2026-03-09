import SwiftUI
import SwiftData

// タグ編集画面（一覧・色変更・名前変更・削除）
struct TagEditView: View {
    @Query(sort: \Tag.name) private var tags: [Tag]
    @Environment(\.modelContext) private var modelContext
    @State private var editingTag: Tag?
    @State private var showNewTagSheet = false
    @State private var isDeleteMode = false
    @State private var selectedForDeletion: Set<UUID> = []

    var body: some View {
        VStack(spacing: 0) {
            // 上部ボタン行
            HStack {
                if isDeleteMode {
                    Button("キャンセル") {
                        isDeleteMode = false
                        selectedForDeletion.removeAll()
                    }
                    .font(.system(size: 14, design: .rounded))

                    Spacer()

                    Button {
                        deleteSelected()
                    } label: {
                        Text("削除(\(selectedForDeletion.count))")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(.red)
                    }
                    .disabled(selectedForDeletion.isEmpty)
                } else {
                    Spacer()

                    Button {
                        isDeleteMode = true
                        selectedForDeletion.removeAll()
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 14))
                            .foregroundStyle(.red.opacity(0.7))
                    }
                    .disabled(tags.isEmpty)

                    Button {
                        showNewTagSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 18))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            // タグ一覧
            List {
                ForEach(tags) { tag in
                    Button {
                        if isDeleteMode {
                            toggleDeletion(tag)
                        } else {
                            editingTag = tag
                        }
                    } label: {
                        HStack(spacing: 10) {
                            // 削除モード時のチェックマーク
                            if isDeleteMode {
                                Image(systemName: selectedForDeletion.contains(tag.id)
                                      ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 20))
                                    .foregroundStyle(selectedForDeletion.contains(tag.id)
                                                     ? .red : .gray.opacity(0.4))
                            }

                            // カラー付きタグ名
                            Text(tag.name)
                                .font(.system(size: 15, weight: .medium, design: .rounded))
                                .foregroundStyle(.primary.opacity(0.85))
                                .lineLimit(1)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(tagColor(for: tag.colorIndex))
                                )

                            Spacer()

                            if !isDeleteMode {
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
                }
            }
        }
        .navigationTitle("タグ編集")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $editingTag) { tag in
            TagDetailEditView(tag: tag)
        }
        .sheet(isPresented: $showNewTagSheet) {
            NewTagSheetView()
        }
    }

    private func toggleDeletion(_ tag: Tag) {
        if selectedForDeletion.contains(tag.id) {
            selectedForDeletion.remove(tag.id)
        } else {
            selectedForDeletion.insert(tag.id)
        }
    }

    private func deleteSelected() {
        for tag in tags where selectedForDeletion.contains(tag.id) {
            for memo in tag.memos {
                memo.tags.removeAll { $0.id == tag.id }
            }
            modelContext.delete(tag)
        }
        selectedForDeletion.removeAll()
        isDeleteMode = false
    }
}

// カラーパレット（28色、コンパクト表示）
struct ColorPaletteGrid: View {
    @Binding var selectedIndex: Int

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 6) {
            ForEach(1...28, id: \.self) { index in
                Button {
                    selectedIndex = index
                } label: {
                    RoundedRectangle(cornerRadius: 5)
                        .fill(tagColor(for: index))
                        .frame(height: 28)
                        .overlay(
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(
                                    selectedIndex == index
                                        ? Color.primary : Color.clear,
                                    lineWidth: 2
                                )
                        )
                }
            }
        }
    }
}

// プレビュー枠（タグ:ラベル + タグパネル）
struct TagPreviewBox: View {
    let name: String
    let colorIndex: Int

    private var displayName: String {
        let n = name.isEmpty ? "サンプル" : name
        return n.count > 5 ? String(n.prefix(5)) + "…" : n
    }

    var body: some View {
        HStack(spacing: 8) {
            Text("プレビュー")
                .font(.system(size: 12, design: .rounded))
                .foregroundStyle(.secondary)

            // タグパネル（メイン画面と同じ見た目）
            VStack(alignment: .leading, spacing: 1) {
                Text("タグ:")
                    .font(.system(size: 9, design: .rounded))
                    .foregroundStyle(.tertiary)
                Text(displayName)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary.opacity(0.8))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(tagColor(for: colorIndex))
                    )
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(uiColor: .secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}

// 個別タグ編集シート（名前変更・色変更）
struct TagDetailEditView: View {
    @Bindable var tag: Tag
    @Environment(\.dismiss) private var dismiss

    @State private var editName: String = ""
    @State private var editColorIndex: Int = 1

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
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

                // カラー選択（コンパクト）
                VStack(alignment: .leading, spacing: 6) {
                    Text("カラー")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)

                    ColorPaletteGrid(selectedIndex: $editColorIndex)
                }

                // プレビュー枠
                TagPreviewBox(name: editName, colorIndex: editColorIndex)

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

    private func saveChanges() {
        let trimmed = editName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        tag.name = trimmed
        tag.colorIndex = editColorIndex
        dismiss()
    }
}
