import SwiftUI

// マークダウンプレビュー（全記法対応）
struct MarkdownPreviewView: View {
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            let lines = text.components(separatedBy: "\n")
            var inCodeBlock = false
            var codeLines: [String] = []

            ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                // コードブロックの開始/終了を検出
                // ※ ForEach内でvarは使えないので、コードブロックは別処理
                renderLine(line)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func renderLine(_ line: String) -> some View {
        let trimmed = line.trimmingCharacters(in: .init(charactersIn: " \t"))
        let indent = line.prefix(while: { $0 == " " || $0 == "\t" }).count

        if trimmed.hasPrefix("### ") {
            inlineText(String(trimmed.dropFirst(4)))
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .padding(.top, 6)
        } else if trimmed.hasPrefix("## ") {
            inlineText(String(trimmed.dropFirst(3)))
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .padding(.top, 8)
        } else if trimmed.hasPrefix("# ") {
            inlineText(String(trimmed.dropFirst(2)))
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .padding(.top, 10)
        }
        // 水平線
        else if trimmed.count >= 3 && (
            trimmed.allSatisfy({ $0 == "-" }) ||
            trimmed.allSatisfy({ $0 == "*" }) ||
            trimmed.allSatisfy({ $0 == "_" })
        ) {
            Divider()
                .padding(.vertical, 6)
        }
        // チェックボックス（完了）
        else if trimmed.hasPrefix("- [x] ") || trimmed.hasPrefix("- [X] ") {
            HStack(alignment: .top, spacing: 6) {
                Image(systemName: "checkmark.square.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(.green)
                inlineText(String(trimmed.dropFirst(6)))
                    .strikethrough()
                    .foregroundStyle(.secondary)
            }
            .padding(.leading, CGFloat(indent) * 10)
        }
        // チェックボックス（未完了）
        else if trimmed.hasPrefix("- [ ] ") {
            HStack(alignment: .top, spacing: 6) {
                Image(systemName: "square")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                inlineText(String(trimmed.dropFirst(6)))
            }
            .padding(.leading, CGFloat(indent) * 10)
        }
        // 箇条書き
        else if trimmed.hasPrefix("- ") {
            HStack(alignment: .top, spacing: 6) {
                Text("•")
                    .font(.system(size: 16))
                inlineText(String(trimmed.dropFirst(2)))
            }
            .padding(.leading, CGFloat(indent) * 10)
        }
        // 番号付きリスト
        else if let numEnd = trimmed.firstIndex(of: "."),
                trimmed[trimmed.startIndex..<numEnd].allSatisfy(\.isNumber),
                trimmed.index(after: numEnd) < trimmed.endIndex,
                trimmed[trimmed.index(after: numEnd)] == " " {
            let num = String(trimmed[trimmed.startIndex..<numEnd])
            let content = String(trimmed[trimmed.index(numEnd, offsetBy: 2)...])
            HStack(alignment: .top, spacing: 4) {
                Text("\(num).")
                    .font(.system(size: 16))
                    .foregroundStyle(.secondary)
                inlineText(content)
            }
            .padding(.leading, CGFloat(indent) * 10)
        }
        // 引用
        else if trimmed.hasPrefix("> ") {
            HStack(spacing: 0) {
                Rectangle()
                    .fill(Color.gray.opacity(0.4))
                    .frame(width: 3)
                inlineText(String(trimmed.dropFirst(2)))
                    .italic()
                    .foregroundStyle(.secondary)
                    .padding(.leading, 8)
            }
            .padding(.vertical, 2)
        }
        // コードブロック開始/終了
        else if trimmed.hasPrefix("```") {
            // 簡易表示: ``` 行は非表示にする
            EmptyView()
        }
        // 空行
        else if trimmed.isEmpty {
            Spacer().frame(height: 8)
        }
        // 通常テキスト
        else {
            inlineText(line)
        }
    }

    // インライン記法をパースしてTextを組み立て
    private func inlineText(_ text: String) -> Text {
        parseInline(text)
    }

    // マークダウンのインライン記法をパース（NSRegularExpression使用）
    private func parseInline(_ input: String) -> Text {
        // パターンと対応するスタイル処理
        struct InlineMatch: Comparable {
            let range: Range<String.Index>
            let innerText: String
            let kind: Kind
            enum Kind { case bold, italic, strikethrough, code, link }
            static func < (lhs: InlineMatch, rhs: InlineMatch) -> Bool {
                lhs.range.lowerBound < rhs.range.lowerBound
            }
        }

        var matches: [InlineMatch] = []
        let nsInput = input as NSString

        // 太字 **text**
        if let regex = try? NSRegularExpression(pattern: "\\*\\*(.+?)\\*\\*") {
            for m in regex.matches(in: input, range: NSRange(location: 0, length: nsInput.length)) {
                if let range = Range(m.range, in: input), let inner = Range(m.range(at: 1), in: input) {
                    matches.append(InlineMatch(range: range, innerText: String(input[inner]), kind: .bold))
                }
            }
        }

        // 取消線 ~~text~~
        if let regex = try? NSRegularExpression(pattern: "~~(.+?)~~") {
            for m in regex.matches(in: input, range: NSRange(location: 0, length: nsInput.length)) {
                if let range = Range(m.range, in: input), let inner = Range(m.range(at: 1), in: input) {
                    matches.append(InlineMatch(range: range, innerText: String(input[inner]), kind: .strikethrough))
                }
            }
        }

        // インラインコード `code`
        if let regex = try? NSRegularExpression(pattern: "`([^`]+)`") {
            for m in regex.matches(in: input, range: NSRange(location: 0, length: nsInput.length)) {
                if let range = Range(m.range, in: input), let inner = Range(m.range(at: 1), in: input) {
                    matches.append(InlineMatch(range: range, innerText: String(input[inner]), kind: .code))
                }
            }
        }

        // リンク [text](url)
        if let regex = try? NSRegularExpression(pattern: "\\[([^\\]]+)\\]\\([^)]+\\)") {
            for m in regex.matches(in: input, range: NSRange(location: 0, length: nsInput.length)) {
                if let range = Range(m.range, in: input), let inner = Range(m.range(at: 1), in: input) {
                    matches.append(InlineMatch(range: range, innerText: String(input[inner]), kind: .link))
                }
            }
        }

        // 斜体 *text*（太字と重複しないもの）
        if let regex = try? NSRegularExpression(pattern: "(?<!\\*)\\*(?!\\*)(.+?)(?<!\\*)\\*(?!\\*)") {
            for m in regex.matches(in: input, range: NSRange(location: 0, length: nsInput.length)) {
                if let range = Range(m.range, in: input), let inner = Range(m.range(at: 1), in: input) {
                    // 太字の範囲内に含まれるものは除外
                    let overlaps = matches.contains { $0.range.overlaps(range) }
                    if !overlaps {
                        matches.append(InlineMatch(range: range, innerText: String(input[inner]), kind: .italic))
                    }
                }
            }
        }

        // ソートして重複除去
        matches.sort()
        var filtered: [InlineMatch] = []
        for m in matches {
            if let last = filtered.last, last.range.overlaps(m.range) { continue }
            filtered.append(m)
        }

        // テキストを組み立て
        var result = Text("")
        var currentIndex = input.startIndex

        for m in filtered {
            if currentIndex < m.range.lowerBound {
                result = result + Text(input[currentIndex..<m.range.lowerBound])
            }
            switch m.kind {
            case .bold:
                result = result + Text(m.innerText).bold()
            case .italic:
                result = result + Text(m.innerText).italic()
            case .strikethrough:
                result = result + Text(m.innerText).strikethrough()
            case .code:
                result = result + Text(m.innerText)
                    .font(.system(size: 14, design: .monospaced))
                    .foregroundColor(Color(uiColor: .secondaryLabel))
            case .link:
                result = result + Text(m.innerText)
                    .foregroundColor(.blue)
                    .underline()
            }
            currentIndex = m.range.upperBound
        }

        if currentIndex < input.endIndex {
            result = result + Text(input[currentIndex...])
        }

        return result
    }
}
