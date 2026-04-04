import SwiftUI
import UIKit

// Bear風インラインマークダウンエディタ
// GutteredTextViewと同じUIViewコンテナ方式でラップ（SwiftUIのpadding統一）
struct MarkdownTextEditor: UIViewRepresentable {
    @Binding var text: String
    @Binding var isFocused: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> MarkdownContainerView {
        let container = MarkdownContainerView(text: $text)
        container.textView.delegate = context.coordinator
        container.textView.text = text
        container.applyStyle()

        // カーソル位置の通知を受け取る
        context.coordinator.cursorObserver = NotificationCenter.default.addObserver(
            forName: .markdownCursorFromEnd,
            object: nil,
            queue: .main
        ) { [weak container] notification in
            guard let container, let offset = notification.userInfo?["offset"] as? Int else { return }
            let len = container.textView.text.count
            let pos = max(0, len - offset)
            container.textView.selectedRange = NSRange(location: pos, length: 0)
        }

        return container
    }

    func updateUIView(_ container: MarkdownContainerView, context: Context) {
        guard !context.coordinator.isUpdating else { return }

        // テキスト同期（外部からの変更のみ反映）
        if container.textView.text != text {
            context.coordinator.isUpdating = true
            let selectedRange = container.textView.selectedRange
            container.textView.text = text
            container.applyStyle()
            container.textView.selectedRange = selectedRange
            context.coordinator.isUpdating = false
        }

        // フォーカス管理（LineNumberTextEditorと同じパターン）
        if isFocused && !container.textView.isFirstResponder {
            DispatchQueue.main.async {
                container.textView.becomeFirstResponder()
            }
        } else if !isFocused && container.textView.isFirstResponder {
            container.textView.resignFirstResponder()
        }
    }

    static func dismantleUIView(_ container: MarkdownContainerView, coordinator: Coordinator) {
        if let observer = coordinator.cursorObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, UITextViewDelegate {
        var parent: MarkdownTextEditor
        var isUpdating = false
        var cursorObserver: Any?

        init(_ parent: MarkdownTextEditor) {
            self.parent = parent
        }

        func textViewDidBeginEditing(_ textView: UITextView) {
            DispatchQueue.main.async { self.parent.isFocused = true }
        }

        func textViewDidEndEditing(_ textView: UITextView) {
            DispatchQueue.main.async { self.parent.isFocused = false }
        }

        func textViewDidChange(_ textView: UITextView) {
            guard !isUpdating else { return }
            isUpdating = true
            parent.text = textView.text
            (textView.superview as? MarkdownContainerView)?.applyStyle()
            isUpdating = false
        }

        // 最大文字数制限
        func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
            let current = textView.text ?? ""
            let newLength = current.count - range.length + text.count
            return newLength <= MemoInputViewModel.maxCharacterCount
        }

        deinit {
            if let observer = cursorObserver {
                NotificationCenter.default.removeObserver(observer)
            }
        }
    }
}

// MARK: - UITextViewをラップするコンテナView（GutteredTextViewと同じパターン）

class MarkdownContainerView: UIView {
    let textView: UITextView
    private var textBinding: Binding<String>

    // スタイリング定数（GutteredTextViewのデフォルトと同じ17pt）
    private let baseFontSize: CGFloat = 17
    private let symbolColor = UIColor.systemGray3

    init(text: Binding<String>) {
        // GutteredTextViewと同じTextKit 1を使用（描画位置の統一）
        textView = UITextView(usingTextLayoutManager: false)
        self.textBinding = text
        super.init(frame: .zero)

        textView.font = UIFont.systemFont(ofSize: baseFontSize)
        textView.backgroundColor = .clear
        // TextAreaLayout定数を参照（GutteredTextViewと完全に同じ設定）
        textView.textContainerInset = UIEdgeInsets(
            top: TextAreaLayout.textInsetTop,
            left: TextAreaLayout.textInsetLeft,
            bottom: TextAreaLayout.textInsetBottom,
            right: TextAreaLayout.textInsetRight
        )
        textView.contentInset.bottom = TextAreaLayout.contentInsetBottom
        textView.textContainer.lineFragmentPadding = TextAreaLayout.lineFragmentPadding
        textView.autocorrectionType = .default
        textView.autocapitalizationType = .none
        textView.isScrollEnabled = true
        textView.alwaysBounceVertical = true

        addSubview(textView)
        backgroundColor = .clear

        // キーボード直上にマークダウンツールバーを配置
        let toolbar = MarkdownToolbar(text: text)
        let hostingController = UIHostingController(rootView: toolbar)
        hostingController.view.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 44)
        hostingController.view.backgroundColor = .secondarySystemBackground
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        let wrapper = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 44))
        wrapper.addSubview(hostingController.view)
        NSLayoutConstraint.activate([
            hostingController.view.leadingAnchor.constraint(equalTo: wrapper.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: wrapper.trailingAnchor),
            hostingController.view.topAnchor.constraint(equalTo: wrapper.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: wrapper.bottomAnchor),
        ])
        textView.inputAccessoryView = wrapper

        // キーボード表示/非表示でcontentInset.bottomを自動調整
        NotificationCenter.default.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    @objc private func adjustForKeyboard(_ notification: Notification) {
        let baseBottom = TextAreaLayout.contentInsetBottom
        guard let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
            textView.contentInset.bottom = baseBottom
            return
        }
        let tvBottom = textView.convert(textView.bounds, to: nil).maxY
        let kbTop = frame.origin.y
        let overlap = max(0, tvBottom - kbTop)
        textView.contentInset.bottom = baseBottom + overlap
        textView.verticalScrollIndicatorInsets.bottom = overlap
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        textView.frame = bounds
    }

    // MARK: - マークダウンスタイリング

    func applyStyle() {
        let storage = textView.textStorage
        let fullText = storage.string
        guard !fullText.isEmpty else { return }
        let fullRange = NSRange(location: 0, length: storage.length)

        let defaultFont = UIFont.systemFont(ofSize: baseFontSize)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 4

        storage.beginEditing()

        storage.setAttributes([
            .font: defaultFont,
            .foregroundColor: UIColor.label,
            .paragraphStyle: paragraphStyle,
        ], range: fullRange)

        storage.removeAttribute(.backgroundColor, range: fullRange)
        storage.removeAttribute(.strikethroughStyle, range: fullRange)

        let lines = fullText.components(separatedBy: "\n")
        var currentLocation = 0

        for line in lines {
            let lineLen = (line as NSString).length
            let lineRange = NSRange(location: currentLocation, length: lineLen)

            let trimmed = line.drop(while: { $0 == " " || $0 == "\t" })
            let indent = line.count - trimmed.count

            if line.hasPrefix("### ") {
                styleHeading(storage, lineRange: lineRange, prefixLength: 4, fontSize: baseFontSize + 2)
            } else if line.hasPrefix("## ") {
                styleHeading(storage, lineRange: lineRange, prefixLength: 3, fontSize: baseFontSize + 5)
            } else if line.hasPrefix("# ") {
                styleHeading(storage, lineRange: lineRange, prefixLength: 2, fontSize: baseFontSize + 8)
            }
            // 水平線
            else if lineLen >= 3 && (
                line.allSatisfy({ $0 == "-" }) ||
                line.allSatisfy({ $0 == "*" }) ||
                line.allSatisfy({ $0 == "_" })
            ) {
                storage.addAttribute(.foregroundColor, value: symbolColor, range: lineRange)
            }
            // チェックボックス（ネスト対応）
            else if String(trimmed).hasPrefix("- [ ] ") || String(trimmed).hasPrefix("- [x] ") || String(trimmed).hasPrefix("- [X] ") {
                styleSymbol(storage, lineRange: lineRange, symbolLength: indent + 6)
                if indent > 0 { applyIndent(storage, lineRange: lineRange, level: indent) }
                if String(trimmed).hasPrefix("- [x] ") || String(trimmed).hasPrefix("- [X] ") {
                    let contentRange = NSRange(location: lineRange.location + indent + 6, length: max(0, lineLen - indent - 6))
                    storage.addAttribute(.strikethroughStyle, value: NSUnderlineStyle.single.rawValue, range: contentRange)
                    storage.addAttribute(.foregroundColor, value: UIColor.secondaryLabel, range: contentRange)
                }
            }
            // 箇条書き（ネスト対応）
            else if String(trimmed).hasPrefix("- ") {
                styleSymbol(storage, lineRange: lineRange, symbolLength: indent + 2)
                if indent > 0 { applyIndent(storage, lineRange: lineRange, level: indent) }
            }
            // 番号付きリスト
            else if let dotRange = matchNumberedList(String(trimmed)) {
                let prefixLen = indent + dotRange
                styleSymbol(storage, lineRange: lineRange, symbolLength: prefixLen)
                if indent > 0 { applyIndent(storage, lineRange: lineRange, level: indent) }
            }
            else if line.hasPrefix("> ") {
                styleSymbol(storage, lineRange: lineRange, symbolLength: 2)
                let contentRange = NSRange(location: lineRange.location + 2, length: max(0, lineLen - 2))
                storage.addAttribute(.font, value: UIFont.italicSystemFont(ofSize: baseFontSize), range: contentRange)
                storage.addAttribute(.foregroundColor, value: UIColor.secondaryLabel, range: contentRange)
            }
            else if line.hasPrefix("```") {
                storage.addAttribute(.foregroundColor, value: symbolColor, range: lineRange)
                storage.addAttribute(.font, value: UIFont.monospacedSystemFont(ofSize: baseFontSize - 1, weight: .regular), range: lineRange)
            }

            applyInlineStyles(storage, in: lineRange, text: line)
            currentLocation += lineLen + 1
        }

        storage.endEditing()

        // カーソル位置の入力属性をデフォルトに戻す
        let defaultParagraph = NSMutableParagraphStyle()
        defaultParagraph.lineSpacing = 4
        textView.typingAttributes = [
            .font: defaultFont,
            .foregroundColor: UIColor.label,
            .paragraphStyle: defaultParagraph,
        ]

        // applyStyle後にinsetを再確認（textStorage操作で変わる場合の保険）
        textView.textContainerInset = UIEdgeInsets(
            top: TextAreaLayout.textInsetTop,
            left: TextAreaLayout.textInsetLeft,
            bottom: TextAreaLayout.textInsetBottom,
            right: TextAreaLayout.textInsetRight
        )
        textView.textContainer.lineFragmentPadding = TextAreaLayout.lineFragmentPadding
    }

    private func styleHeading(_ storage: NSTextStorage, lineRange: NSRange, prefixLength: Int, fontSize: CGFloat) {
        let headingFont = UIFont.systemFont(ofSize: fontSize, weight: .bold)
        storage.addAttribute(.font, value: headingFont, range: lineRange)
        let symbolRange = NSRange(location: lineRange.location, length: min(prefixLength, lineRange.length))
        storage.addAttribute(.foregroundColor, value: symbolColor, range: symbolRange)
    }

    private func styleSymbol(_ storage: NSTextStorage, lineRange: NSRange, symbolLength: Int) {
        let symbolRange = NSRange(location: lineRange.location, length: min(symbolLength, lineRange.length))
        storage.addAttribute(.foregroundColor, value: symbolColor, range: symbolRange)
    }

    private func matchNumberedList(_ line: String) -> Int? {
        guard let first = line.first, first.isNumber else { return nil }
        for (i, ch) in line.enumerated() {
            if ch == "." {
                let nextIndex = line.index(line.startIndex, offsetBy: i + 1, limitedBy: line.endIndex)
                if let nextIndex, line[nextIndex] == " " {
                    return i + 2
                }
                return nil
            }
            if !ch.isNumber { return nil }
        }
        return nil
    }

    private func applyIndent(_ storage: NSTextStorage, lineRange: NSRange, level: Int) {
        let indentParagraph = NSMutableParagraphStyle()
        indentParagraph.lineSpacing = 4
        let indentPoints = CGFloat(level) * 10.0
        indentParagraph.headIndent = indentPoints
        indentParagraph.firstLineHeadIndent = indentPoints
        storage.addAttribute(.paragraphStyle, value: indentParagraph, range: lineRange)
    }

    private func applyInlineStyles(_ storage: NSTextStorage, in lineRange: NSRange, text: String) {
        let nsText = text as NSString

        applyPattern("\\*\\*(.+?)\\*\\*", storage: storage, lineRange: lineRange, nsText: nsText) { matchRange, innerRange in
            let startSymbol = NSRange(location: matchRange.location, length: 2)
            let endSymbol = NSRange(location: matchRange.location + matchRange.length - 2, length: 2)
            storage.addAttribute(.foregroundColor, value: symbolColor, range: startSymbol)
            storage.addAttribute(.foregroundColor, value: symbolColor, range: endSymbol)
            storage.addAttribute(.font, value: UIFont.boldSystemFont(ofSize: baseFontSize), range: innerRange)
        }

        applyPattern("(?<!\\*)\\*(?!\\*)(.+?)(?<!\\*)\\*(?!\\*)", storage: storage, lineRange: lineRange, nsText: nsText) { matchRange, innerRange in
            let startSymbol = NSRange(location: matchRange.location, length: 1)
            let endSymbol = NSRange(location: matchRange.location + matchRange.length - 1, length: 1)
            storage.addAttribute(.foregroundColor, value: symbolColor, range: startSymbol)
            storage.addAttribute(.foregroundColor, value: symbolColor, range: endSymbol)
            storage.addAttribute(.font, value: UIFont.italicSystemFont(ofSize: baseFontSize), range: innerRange)
        }

        applyPattern("~~(.+?)~~", storage: storage, lineRange: lineRange, nsText: nsText) { matchRange, innerRange in
            let startSymbol = NSRange(location: matchRange.location, length: 2)
            let endSymbol = NSRange(location: matchRange.location + matchRange.length - 2, length: 2)
            storage.addAttribute(.foregroundColor, value: symbolColor, range: startSymbol)
            storage.addAttribute(.foregroundColor, value: symbolColor, range: endSymbol)
            storage.addAttribute(.strikethroughStyle, value: NSUnderlineStyle.single.rawValue, range: innerRange)
        }

        applyPattern("`([^`]+)`", storage: storage, lineRange: lineRange, nsText: nsText) { matchRange, innerRange in
            let startSymbol = NSRange(location: matchRange.location, length: 1)
            let endSymbol = NSRange(location: matchRange.location + matchRange.length - 1, length: 1)
            storage.addAttribute(.foregroundColor, value: symbolColor, range: startSymbol)
            storage.addAttribute(.foregroundColor, value: symbolColor, range: endSymbol)
            storage.addAttribute(.font, value: UIFont.monospacedSystemFont(ofSize: baseFontSize - 1, weight: .regular), range: innerRange)
            storage.addAttribute(.backgroundColor, value: UIColor.systemGray6, range: innerRange)
        }

        // リンク [テキスト](URL)
        applyPattern("\\[([^\\]]+)\\]\\(([^)]+)\\)", storage: storage, lineRange: lineRange, nsText: nsText) { matchRange, innerRange in
            let openBracket = NSRange(location: matchRange.location, length: 1)
            storage.addAttribute(.foregroundColor, value: symbolColor, range: openBracket)
            let closeBracketPos = matchRange.location + 1 + innerRange.length
            let closeBracket = NSRange(location: closeBracketPos, length: 1)
            storage.addAttribute(.foregroundColor, value: symbolColor, range: closeBracket)
            storage.addAttribute(.foregroundColor, value: UIColor.systemBlue, range: innerRange)
            storage.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: innerRange)
            let urlPartStart = closeBracketPos + 1
            let urlPartLen = matchRange.location + matchRange.length - urlPartStart
            if urlPartLen > 0 {
                let urlRange = NSRange(location: urlPartStart, length: urlPartLen)
                storage.addAttribute(.foregroundColor, value: symbolColor, range: urlRange)
                storage.addAttribute(.font, value: UIFont.systemFont(ofSize: baseFontSize - 2), range: urlRange)
            }
        }
    }

    private func applyPattern(
        _ pattern: String,
        storage: NSTextStorage,
        lineRange: NSRange,
        nsText: NSString,
        apply: (NSRange, NSRange) -> Void
    ) {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return }
        let matches = regex.matches(in: nsText as String, range: NSRange(location: 0, length: nsText.length))

        for match in matches {
            let matchRange = NSRange(
                location: lineRange.location + match.range.location,
                length: match.range.length
            )
            let innerLocalRange = match.range(at: 1)
            let innerRange = NSRange(
                location: lineRange.location + innerLocalRange.location,
                length: innerLocalRange.length
            )

            guard matchRange.location + matchRange.length <= storage.length,
                  innerRange.location + innerRange.length <= storage.length else { continue }

            apply(matchRange, innerRange)
        }
    }
}
