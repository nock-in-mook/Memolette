import SwiftUI
import SwiftData

// タブの色パレット
private let tabColors: [Color] = [
    .gray.opacity(0.35),       // タグ無し用（グレー）
    Color(red: 0.55, green: 0.80, blue: 0.95),  // 水色
    Color(red: 0.95, green: 0.70, blue: 0.55),  // オレンジ
    Color(red: 0.70, green: 0.90, blue: 0.70),  // 緑
    Color(red: 0.90, green: 0.70, blue: 0.90),  // 紫
    Color(red: 0.95, green: 0.85, blue: 0.55),  // 黄色
    Color(red: 0.95, green: 0.60, blue: 0.60),  // 赤
    Color(red: 0.60, green: 0.75, blue: 0.95),  // 青
]

// タグのインデックスから色を取得
func tagColor(for index: Int) -> Color {
    tabColors[index % tabColors.count]
}

struct TabbedMemoListView: View {
    @Query(sort: \Tag.name) private var tags: [Tag]
    @Query(sort: \Memo.createdAt, order: .reverse) private var allMemos: [Memo]
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTabIndex: Int = 0
    @State private var editingMemo: Memo?

    // タブ一覧：「タグ無し」+ 全タグ
    private var tabItems: [(label: String, tag: Tag?)] {
        var items: [(String, Tag?)] = [("タグ無し", nil)]
        for tag in tags {
            items.append((tag.name, tag))
        }
        return items
    }

    // 選択中のタブに対応するメモ
    private var filteredMemos: [Memo] {
        let item = tabItems[selectedTabIndex]
        if let tag = item.tag {
            return allMemos.filter { memo in
                memo.tags.contains { $0.id == tag.id }
            }
        } else {
            // タグ無し：タグが空のメモ
            return allMemos.filter { $0.tags.isEmpty }
        }
    }

    // 選択中タブの色
    private var currentColor: Color {
        tagColor(for: selectedTabIndex)
    }

    var body: some View {
        VStack(spacing: 0) {
            // タブ行
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: -2) {
                        ForEach(Array(tabItems.enumerated()), id: \.offset) { index, item in
                            tabButton(label: item.label, index: index)
                                .id(index)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.top, 4)
                }
                .onChange(of: selectedTabIndex) { _, newValue in
                    withAnimation(.easeInOut(duration: 0.2)) {
                        proxy.scrollTo(newValue, anchor: .center)
                    }
                }
            }

            // メモ一覧（タブの色を背景に）
            ZStack {
                currentColor
                    .ignoresSafeArea(edges: .bottom)

                if filteredMemos.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "note.text")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        Text("メモがありません")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(filteredMemos) { memo in
                                MemoCardView(memo: memo)
                                    .onTapGesture {
                                        editingMemo = memo
                                    }
                                    .contextMenu {
                                        Button {
                                            UIPasteboard.general.string = memo.content
                                        } label: {
                                            Label("コピー", systemImage: "doc.on.doc")
                                        }
                                        Button(role: .destructive) {
                                            modelContext.delete(memo)
                                        } label: {
                                            Label("削除", systemImage: "trash")
                                        }
                                    }
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.top, 8)
                        .padding(.bottom, 20)
                    }
                }
            }
            .animation(.easeInOut(duration: 0.2), value: selectedTabIndex)
        }
        .sheet(item: $editingMemo) { memo in
            TagTitleSheetView(memo: memo)
        }
    }

    private func tabButton(label: String, index: Int) -> some View {
        let isSelected = selectedTabIndex == index
        let color = tagColor(for: index)

        return Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                selectedTabIndex = index
            }
        } label: {
            Text(label)
                .font(.caption)
                .fontWeight(isSelected ? .bold : .regular)
                .foregroundStyle(isSelected ? .primary : .secondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    TrapezoidTabShape()
                        .fill(isSelected ? color : color.opacity(0.4))
                )
                .offset(y: isSelected ? 2 : 0) // 選択中のタブは少し下にずれて繋がって見える
        }
        .zIndex(isSelected ? 1 : 0) // 選択中のタブを前面に
    }
}

// カード風のメモ行（背景色付きリスト用）
struct MemoCardView: View {
    let memo: Memo

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(memo.title.isEmpty ? "無題" : memo.title)
                    .font(.headline)
                    .lineLimit(1)

                Spacer()

                Button {
                    UIPasteboard.general.string = memo.content
                } label: {
                    Image(systemName: "doc.on.doc")
                        .font(.caption)
                        .foregroundStyle(.gray)
                }
                .buttonStyle(.plain)
            }

            Text(memo.content)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(3)

            Text(memo.createdAt, style: .relative)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(12)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
