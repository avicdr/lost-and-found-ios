import SwiftUI
import SwiftData

struct HomeView: View {
    @Binding var selectedTab: AppTab
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ItemReport.createdAt, order: .reverse) private var reports: [ItemReport]
    @Query(sort: \MatchRecord.score, order: .reverse) private var matchRecords: [MatchRecord]
    @State private var showingReportLost = false
    @State private var showingReportFound = false
    @State private var selectedItem: ItemReport?
    @State private var selectedMatch: ItemMatch?
    @State private var loadError: String?

    private var activeMatches: [ItemMatch] { matchRecords.compactMap(matchPresentation) }
    private var recentItems: [ItemReport] { Array(reports.filter(\.isActive).prefix(6)) }
    private var myActiveReports: [ItemReport] { reports.filter { $0.ownerID == LocalIdentity.userID && $0.isActive } }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.xl) {
                        headerSection.padding(.horizontal, AppTheme.Spacing.lg).padding(.top, AppTheme.Spacing.sm)
                        actionCardsSection.padding(.horizontal, AppTheme.Spacing.lg)
                        if !myActiveReports.isEmpty { myReportsSection }
                        if !activeMatches.isEmpty { matchesSection }
                        recentSection
                    }.padding(.bottom, AppTheme.Spacing.xl)
                }.scrollIndicators(.hidden)
            }
            .navigationBarHidden(true)
            .task { await prepareData() }
            .alert("Couldn’t load reports", isPresented: Binding(get: { loadError != nil }, set: { if !$0 { loadError = nil } })) { Button("OK", role: .cancel) {} } message: { Text(loadError ?? "") }
            .sheet(isPresented: $showingReportLost) { ReportItemView(mode: .lost) }
            .sheet(isPresented: $showingReportFound) { ReportItemView(mode: .found) }
            .sheet(item: $selectedItem) { ItemDetailView(item: $0) }
            .sheet(item: $selectedMatch) { MatchDetailView(match: $0) }
        }
    }

    private func prepareData() async {
        do {
            let reports = ReportRepository(context: modelContext)
            // Demo data is seeded only once and never read directly by UI.
            if UserDefaults.standard.bool(forKey: "sahaay.demo-mode") { try reports.seedDemoIfNeeded() }
            try MatchRepository(context: modelContext).refreshMatches()
        } catch { loadError = error.localizedDescription }
    }

    private func matchPresentation(_ record: MatchRecord) -> ItemMatch? {
        guard let lost = reports.first(where: { $0.id == record.lostReportID }), let found = reports.first(where: { $0.id == record.foundReportID }) else { return nil }
        return ItemMatch(record: record, lostReport: lost, foundReport: found)
    }

    private var headerSection: some View { VStack(alignment: .leading, spacing: 6) {
        Text("Sahaay").font(.system(size: 38, weight: .bold, design: .rounded))
        Text("Find what matters. Return what doesn't belong to you.").font(AppTheme.Font.callout).foregroundStyle(.secondary)
    }}

    private var actionCardsSection: some View { VStack(spacing: 12) {
        HomeActionCard(icon: "magnifyingglass", title: "Lost Something?", subtitle: "Tell us what you're looking for.", buttonTitle: "Report Lost Item", accentColor: AppTheme.Color.lost) { showingReportLost = true }
        HomeActionCard(icon: "hand.raised.fill", title: "Found Something?", subtitle: "Help someone get it back.", buttonTitle: "Report Found Item", accentColor: AppTheme.Color.found) { showingReportFound = true }
    }}

    private var myReportsSection: some View { VStack(alignment: .leading, spacing: 10) {
        SectionHeader(title: "Your Active Reports", action: "Profile") { selectedTab = .profile }.padding(.horizontal, AppTheme.Spacing.lg)
        ForEach(myActiveReports.prefix(3)) { report in ItemCard(item: report).onTapGesture { selectedItem = report } }.padding(.horizontal, AppTheme.Spacing.lg)
    }}

    private var matchesSection: some View { VStack(alignment: .leading, spacing: 12) {
        SectionHeader(title: "Possible Matches", action: "See All") { selectedTab = .matches }.padding(.horizontal, AppTheme.Spacing.lg)
        ScrollView(.horizontal, showsIndicators: false) { HStack(spacing: 12) { ForEach(activeMatches) { match in CompactMatchCard(match: match).frame(width: 280).onTapGesture { selectedMatch = match } }.padding(.horizontal, AppTheme.Spacing.lg) } }
    }}

    private var recentSection: some View { VStack(alignment: .leading, spacing: 12) {
        SectionHeader(title: "Recent Campus Reports", action: "See All") { selectedTab = .explore }.padding(.horizontal, AppTheme.Spacing.lg)
        if recentItems.isEmpty { EmptyStateView(icon: "clock", title: "No reports yet.", subtitle: "Campus reports will appear here.").frame(height: 180) }
        else { ForEach(recentItems) { report in ItemCard(item: report).onTapGesture { selectedItem = report } }.padding(.horizontal, AppTheme.Spacing.lg) }
    }}
}

struct HomeActionCard: View {
    let icon: String; let title: String; let subtitle: String; let buttonTitle: String; let accentColor: Color; let action: () -> Void
    var body: some View { Button(action: action) { VStack(alignment: .leading, spacing: 16) {
        HStack(spacing: 14) { ZStack { RoundedRectangle(cornerRadius: 14).fill(accentColor.opacity(0.15)).frame(width: 52, height: 52); Image(systemName: icon).font(.system(size: 22, weight: .semibold)).foregroundStyle(accentColor) }
            VStack(alignment: .leading, spacing: 3) { Text(title).font(AppTheme.Font.title3).foregroundStyle(.primary); Text(subtitle).font(AppTheme.Font.subheadline).foregroundStyle(.secondary) }; Spacer() }
        HStack { Text(buttonTitle).font(AppTheme.Font.headline); Spacer(); Image(systemName: "arrow.right") }.foregroundStyle(.white).padding(.horizontal, 18).padding(.vertical, 14).background(accentColor).clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.md))
    }.padding(18).cardStyle() }.buttonStyle(.plain).accessibilityLabel(title).accessibilityHint(buttonTitle) }
}

struct CompactMatchCard: View {
    let match: ItemMatch
    var body: some View { VStack(alignment: .leading, spacing: 10) {
        HStack { Text("Possible match").font(AppTheme.Font.overline).foregroundStyle(.secondary); Spacer(); ConfidenceBadge(confidence: match.confidence) }
        Text(match.foundReport.name).font(AppTheme.Font.headline).lineLimit(2)
        Label("Found near \(match.foundReport.approximateLocation)", systemImage: "location.fill").font(AppTheme.Font.caption).foregroundStyle(.secondary).lineLimit(1)
        ForEach(match.reasons.prefix(2)) { Label($0.text, systemImage: $0.icon).font(AppTheme.Font.caption).foregroundStyle(.secondary).lineLimit(1) }
        HStack { Spacer(); Text("View Match").font(AppTheme.Font.caption).fontWeight(.semibold).foregroundStyle(Color.accentColor); Image(systemName: "arrow.right").font(.caption).foregroundStyle(Color.accentColor) }
    }.padding(16).cardStyle() }
}

#Preview { HomeView(selectedTab: .constant(.home)).modelContainer(for: [ItemReport.self, MatchRecord.self], inMemory: true) }
