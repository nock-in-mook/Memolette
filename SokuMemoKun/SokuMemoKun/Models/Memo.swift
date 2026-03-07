import Foundation
import SwiftData

@Model
final class Memo {
    var id: UUID = UUID()
    var content: String = ""
    var title: String = ""
    @Relationship(inverse: \Tag.memos) var tags: [Tag] = []
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    init(content: String, title: String = "", tags: [Tag] = []) {
        self.id = UUID()
        self.content = content
        self.title = title
        self.tags = tags
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
