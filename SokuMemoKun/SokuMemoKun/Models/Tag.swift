import Foundation
import SwiftData

@Model
final class Tag {
    var id: UUID = UUID()
    var name: String = ""
    var memos: [Memo] = []

    init(name: String) {
        self.id = UUID()
        self.name = name
    }
}
