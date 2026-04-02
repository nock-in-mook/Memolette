import Foundation
import SwiftData

@Model
final class Tag {
    var id: UUID = UUID()
    var name: String = ""
    var colorIndex: Int = 1
    var gridSize: Int = 2  // 0=小(2×4), 1=中(3×6), 2=大(4×8)
    var memos: [Memo] = []
    var todoItems: [TodoItem] = []  // ToDoアイテムとの多対多リレーション
    var todoLists: [TodoList] = []   // ToDoリストとの多対多リレーション
    var parentTagID: UUID?  // nil = トップレベルタグ（親タグ）
    var sortOrder: Int = 0  // タブの並び順（小さいほど左）

    var isSystem: Bool = false   // システムタグ（TODO等）はtrue、ユーザー作成はfalse

    init(name: String, colorIndex: Int = 1, parentTagID: UUID? = nil, isSystem: Bool = false) {
        self.id = UUID()
        self.name = name
        self.colorIndex = colorIndex
        self.parentTagID = parentTagID
        self.isSystem = isSystem
    }
}
