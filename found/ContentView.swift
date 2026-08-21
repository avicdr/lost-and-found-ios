import SwiftUI
import SwiftData

// MARK: - AppTab Enum

enum AppTab: String, CaseIterable, Hashable {
    case home, explore, report, matches, profile

    var title: String {
        switch self {
        case .home: return "Home"
        case .explore: return "Explore"
        case .report: return "Report"
        case .matches: return "Matches"
        case .profile: return "Profile"
        }
    }

    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .explore: return "map.fill"
        case .report: return "plus.circle.fill"
        case .matches: return "sparkles"
        case .profile: return "person.fill"
        }
    }
}

// MARK: - Root TabView

struct ContentView: View {

    @State private var selectedTab: AppTab = .home
    @State private var locationService = LocationService()
    @State private var notificationService = NotificationService()

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Home", systemImage: "house.fill", value: .home) {
                HomeView(selectedTab: $selectedTab)
            }

            Tab("Explore", systemImage: "map.fill", value: .explore) {
                ExploreView()
            }

            Tab("Report", systemImage: "plus.circle.fill", value: .report) {
                ReportHubView()
            }

            Tab("Matches", systemImage: "sparkles", value: .matches) {
                MatchesView()
            }

            Tab("Profile", systemImage: "person.fill", value: .profile) {
                ProfileView()
            }
        }
        .environment(locationService)
        .environment(notificationService)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: ItemReport.self, inMemory: true)
}
