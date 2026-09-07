import SwiftUI
import SwiftData

@main
struct foundApp: App {
    init() {
        #if DEBUG
        UserDefaults.standard.register(defaults: ["lostandfound.demo-mode": true])
        #endif
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [
            Item.self, ItemReport.self, MatchRecord.self, ClaimRequest.self,
            ReturnArrangement.self, CoordinationMessage.self, ActivityEvent.self, ModerationReport.self
        ])
    }
}
