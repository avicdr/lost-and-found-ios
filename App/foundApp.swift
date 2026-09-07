import SwiftUI
import SwiftData

@main
struct foundApp: App {
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
