import SwiftUI
import SwiftData

@main
struct SokuMemoKunApp: App {
    var body: some Scene {
        WindowGroup {
            MainView()
                .onAppear {
                    createDefaultTagsIfNeeded()
                }
        }
        .modelContainer(for: [Memo.self, Tag.self])
    }

    // 初回起動時にデフォルトタグを作成 + 既存タグの色修正
    private func createDefaultTagsIfNeeded() {
        guard let container = try? ModelContainer(for: Memo.self, Tag.self) else { return }
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
            // 既存タグの色が全て同じ(=未設定)なら順番に色を振り直す
            let allSame = existingTags.allSatisfy { $0.colorIndex == existingTags[0].colorIndex }
            if allSame && existingTags.count > 1 {
                for (i, tag) in existingTags.enumerated() {
                    tag.colorIndex = (i % 7) + 1
                }
            }
        }
        try? context.save()
    }
}
