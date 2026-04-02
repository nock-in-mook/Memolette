import Foundation
import SwiftData

@Model
final class TodoList {
    var id: UUID = UUID()
    var title: String = ""
    var isPinned: Bool = false       // トップに常時固定
    var isLocked: Bool = false       // 削除防止ロック
    var manualSortOrder: Int = 0     // 手動並び順
    @Relationship(inverse: \Tag.todoLists) var tags: [Tag] = []
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    init(title: String, tags: [Tag] = []) {
        self.id = UUID()
        self.title = title
        self.isPinned = false
        self.isLocked = false
        self.tags = tags
        self.manualSortOrder = 0
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
