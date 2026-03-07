import SwiftUI
import SwiftData

@main
struct SokuMemoKunApp: App {
    var body: some Scene {
        WindowGroup {
            MainView()
        }
        .modelContainer(for: [Memo.self, Tag.self])
    }
}
