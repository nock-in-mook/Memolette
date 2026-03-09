import SwiftUI
import SwiftData

@main
struct SokuMemoKunApp: App {
    let sharedContainer: ModelContainer

    init() {
        let container = try! ModelContainer(for: Memo.self, Tag.self)
        self.sharedContainer = container
        Self.setupDefaultTags(container: container)
    }

    var body: some Scene {
        WindowGroup {
            MainView()
        }
        .modelContainer(sharedContainer)
    }

    // 初回起動時にデフォルトタグを作成 + 既存タグの色修正
    private static func setupDefaultTags(container: ModelContainer) {
        let context = ModelContext(container)
        let descriptor = FetchDescriptor<Tag>(sortBy: [SortDescriptor(\Tag.name)])
        let existingTags = (try? context.fetch(descriptor)) ?? []

        if existingTags.isEmpty {
            // 新規: デフォルトタグ作成
            let defaults: [(String, Int)] = [("仕事", 1), ("趣味", 2), ("買い物", 3), ("アイデア", 4)]
            for (name, color) in defaults {
                context.insert(Tag(name: name, colorIndex: color))
            }
        } else {
            // 既存タグの色が未設定（全部同じ）なら順番に振り直す
            let needsFix = existingTags.count > 1 && Set(existingTags.map { $0.colorIndex }).count <= 1
            if needsFix {
                for (i, tag) in existingTags.enumerated() {
                    tag.colorIndex = (i % 7) + 1
                }
            }
        }
        try? context.save()
    }
}
