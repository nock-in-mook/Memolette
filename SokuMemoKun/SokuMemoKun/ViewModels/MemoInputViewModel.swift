import SwiftUI
import SwiftData

@Observable
class MemoInputViewModel {
    var inputText: String = ""
    var showTagTitleSheet: Bool = false
    var savedMemo: Memo?

    var canSave: Bool {
        !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func save(context: ModelContext) {
        guard canSave else { return }
        let memo = Memo(content: inputText.trimmingCharacters(in: .whitespacesAndNewlines))
        context.insert(memo)
        savedMemo = memo
        showTagTitleSheet = true
        inputText = ""
    }
}
