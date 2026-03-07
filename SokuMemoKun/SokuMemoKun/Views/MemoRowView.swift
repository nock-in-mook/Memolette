import SwiftUI

struct MemoRowView: View {
    let memo: Memo

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                // タイトル
                Text(memo.title.isEmpty ? "無題" : memo.title)
                    .font(.headline)
                    .lineLimit(1)

                // タグ表示
                ForEach(memo.tags) { tag in
                    Text("#\(tag.name)")
                        .font(.caption)
                        .foregroundStyle(.blue)
                }

                Spacer()

                // コピーボタン
                Button {
                    UIPasteboard.general.string = memo.content
                } label: {
                    Image(systemName: "doc.on.doc")
                        .font(.caption)
                        .foregroundStyle(.gray)
                }
                .buttonStyle(.plain)
            }

            // 本文プレビュー
            Text(memo.content)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)

            // 作成日時
            Text(memo.createdAt, style: .relative)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 2)
    }
}
