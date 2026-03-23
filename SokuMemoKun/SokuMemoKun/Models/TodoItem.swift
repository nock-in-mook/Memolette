import Foundation
import SwiftData

@Model
final class TodoItem {
    var id: UUID = UUID()
    var listID: UUID = UUID()    // 所属するTodoListのID
    var title: String = ""
    var isDone: Bool = false
    var parentID: UUID?          // nil = ルートレベル
    var sortOrder: Int = 0       // 同階層内の並び順
    @Relationship(inverse: \Tag.todoItems) var tags: [Tag] = []
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    // 将来拡張用
    var dueDate: Date?           // 期限
    var memo: String?            // 補足テキスト

    init(title: String, listID: UUID, parentID: UUID? = nil, sortOrder: Int = 0, tags: [Tag] = []) {
        self.id = UUID()
        self.listID = listID
        self.title = title
        self.isDone = false
        self.parentID = parentID
        self.sortOrder = sortOrder
        self.tags = tags
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
