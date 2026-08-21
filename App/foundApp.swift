import SwiftUI
import SwiftData

@main
struct foundApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Item.self, ItemReport.self])
    }
}
