import SwiftUI
import SwiftData

// 既存メモの閲覧・編集画面（全画面）
struct MemoDetailView: View {
    @Bindable var memo: Memo
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Tag.name) private var allTags: [Tag]

    @State private var isEditing = false
    @State private var editText: String = ""
    @State private var editTitle: String = ""

    // マークダウンレイアウト設定
    @AppStorage("markdownLayout") private var layoutRaw: String = MarkdownLayout.split.rawValue

    private var layout: MarkdownLayout {
        MarkdownLayout(rawValue: layoutRaw) ?? .split
    }

    // メモのタグ情報
    private var parentTag: Tag? {
        memo.tags.first(where: { $0.parentTagID == nil })
    }
    private var childTag: Tag? {
        memo.tags.first(where: { $0.parentTagID != nil })
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if isEditing {
                    editingView
                } else {
                    readingView
                }
            }
            .navigationTitle(isEditing ? "編集中" : "メモ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") {
                        if isEditing {
                            // 編集内容を保存してから閉じる
                            saveEdits()
                        }
                        dismiss()
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    if isEditing {
                        Button("完了") {
                            saveEdits()
                            isEditing = false
                        }
                    } else {
                        Button {
                            startEditing()
                        } label: {
                            Label("編集", systemImage: "pencil")
                        }
                    }
                }
            }
        }
    }

    // 閲覧モード
    private var readingView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                // タイトル
                if !memo.title.isEmpty {
                    Text(memo.title)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                }

                // タグ表示
                if parentTag != nil || childTag != nil {
                    HStack(spacing: 6) {
                        if let parent = parentTag {
                            Text(parent.name)
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(tagColor(for: parent.colorIndex))
                                )
                        }
                        if let child = childTag {
                            Text("› \(child.name)")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(tagColor(for: child.colorIndex))
                                )
                        }
                    }
                }

                Divider()

                // 本文
                if memo.isMarkdown {
                    markdownContent
                } else {
                    Text(memo.content)
                        .font(.system(size: 17))
                        .foregroundStyle(.primary)
                        .textSelection(.enabled)
                }

                Spacer(minLength: 20)

                // 日時情報
                HStack {
                    Text("作成: \(memo.createdAt.formatted(date: .abbreviated, time: .shortened))")
                    Spacer()
                    Text("更新: \(memo.updatedAt.formatted(date: .abbreviated, time: .shortened))")
                }
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
            }
            .padding(16)
        }
    }

    // マークダウン本文表示
    private var markdownContent: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(Array(memo.content.components(separatedBy: "\n").enumerated()), id: \.offset) { _, line in
                markdownLine(line)
            }
        }
    }

    // 編集モード
    private var editingView: some View {
        VStack(spacing: 0) {
            // タイトル入力
            TextField("タイトル（任意）", text: $editTitle)
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)

            Divider()
                .padding(.horizontal, 12)

            // 本文入力
            TextEditor(text: $editText)
                .font(.system(size: 17))
                .padding(.horizontal, 8)
                .padding(.top, 4)
        }
    }

    private func startEditing() {
        editText = memo.content
        editTitle = memo.title
        isEditing = true
    }

    private func saveEdits() {
        memo.content = editText
        memo.title = editTitle
        memo.updatedAt = Date()
    }

    // マークダウン1行レンダリング（FullEditorViewと同じロジック）
    @ViewBuilder
    private func markdownLine(_ line: String) -> some View {
        if line.hasPrefix("### ") {
            Text(String(line.dropFirst(4)))
                .font(.system(size: 18, weight: .bold, design: .rounded))
        } else if line.hasPrefix("## ") {
            Text(String(line.dropFirst(3)))
                .font(.system(size: 20, weight: .bold, design: .rounded))
        } else if line.hasPrefix("# ") {
            Text(String(line.dropFirst(2)))
                .font(.system(size: 24, weight: .bold, design: .rounded))
        } else if line.hasPrefix("- ") {
            HStack(alignment: .top, spacing: 6) {
                Text("•")
                    .font(.system(size: 16))
                Text(String(line.dropFirst(2)))
                    .font(.system(size: 16))
            }
        } else if line.hasPrefix("> ") {
            Text(String(line.dropFirst(2)))
                .font(.system(size: 16, design: .serif))
                .italic()
                .padding(.leading, 10)
                .overlay(
                    Rectangle()
                        .fill(Color.gray.opacity(0.4))
                        .frame(width: 3),
                    alignment: .leading
                )
        } else if line.trimmingCharacters(in: .whitespaces).isEmpty {
            Spacer().frame(height: 8)
        } else {
            Text(line)
                .font(.system(size: 16))
                .textSelection(.enabled)
        }
    }
}
