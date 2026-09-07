import SwiftUI
import SwiftData

struct MatchesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var reports: [ItemReport]
    @Query(sort: \MatchRecord.score, order: .reverse) private var records: [MatchRecord]
    @State private var selectedMatch: ItemMatch?
    private var matches: [ItemMatch] { records.compactMap { record in guard let lost = reports.first(where: { $0.id == record.lostReportID }), let found = reports.first(where: { $0.id == record.foundReportID }) else { return nil }; return ItemMatch(record: record, lostReport: lost, foundReport: found) } }
    var body: some View { NavigationStack { ZStack { Color(.systemGroupedBackground).ignoresSafeArea(); Group { if matches.isEmpty { EmptyStateView.noMatches } else { ScrollView { VStack(alignment: .leading, spacing: 20) { section("Strong Matches", matches.filter { $0.confidenceTier == .high }); section("Possible Matches", matches.filter { $0.confidenceTier != .high }) }.padding() }.scrollIndicators(.hidden) } } }.navigationTitle("Matches").navigationBarTitleDisplayMode(.large).task { try? MatchRepository(context: modelContext).refreshMatches() }.sheet(item: $selectedMatch) { MatchDetailView(match: $0) } } }
    private func section(_ title: String, _ rows: [ItemMatch]) -> some View { Group { if !rows.isEmpty { VStack(alignment: .leading, spacing: 10) { Text(title).font(AppTheme.Font.title3); ForEach(rows) { match in FullMatchCard(match: match).onTapGesture { selectedMatch = match } } } } } }
}

struct FullMatchCard: View { let match: ItemMatch
    var body: some View { VStack(alignment: .leading, spacing: 12) { HStack { CategoryIcon(category: match.lostReport.categoryEnum, size: 48); VStack(alignment: .leading) { Text("Possible Match").font(AppTheme.Font.overline).foregroundStyle(.secondary); Text(match.foundReport.name).font(AppTheme.Font.headline); Text("Lost: \(match.lostReport.name)").font(AppTheme.Font.caption).foregroundStyle(.secondary) }; Spacer(); ConfidenceBadge(confidence: match.confidence) }; Label(match.foundReport.approximateLocation, systemImage: "location.fill").font(AppTheme.Font.caption).foregroundStyle(.secondary); ForEach(match.reasons.prefix(3)) { Label($0.text, systemImage: $0.icon).font(AppTheme.Font.caption).foregroundStyle(.secondary) }; HStack { Spacer(); Text("Why this matches").font(AppTheme.Font.caption).foregroundStyle(Color.accentColor) } }.padding(16).cardStyle() }
}

struct MatchDetailView: View { let match: ItemMatch; @Environment(\.dismiss) private var dismiss; @State private var showingClaim = false
    var body: some View { NavigationStack { ScrollView { VStack(alignment: .leading, spacing: 20) { HStack { CategoryIcon(category: match.lostReport.categoryEnum, size: 56); VStack(alignment: .leading) { Text("Potential match").font(AppTheme.Font.overline).foregroundStyle(.secondary); Text(match.foundReport.name).font(AppTheme.Font.title2); ConfidenceBadge(confidence: match.confidence) } }; HStack(spacing: 12) { summary(match.lostReport, "Lost item"); Image(systemName: "arrow.left.arrow.right").foregroundStyle(.secondary); summary(match.foundReport, "Found item") }; VStack(alignment: .leading, spacing: 10) { Text("WHY THIS MATCHES").font(AppTheme.Font.overline).foregroundStyle(.secondary); ForEach(match.reasons) { Label($0.text, systemImage: $0.icon).font(AppTheme.Font.subheadline) }.padding(16).background(Color(.secondarySystemGroupedBackground)).clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.md)) }; Button { showingClaim = true } label: { Label("This is mine", systemImage: "hand.raised.fill").frame(maxWidth: .infinity) }.buttonStyle(PrimaryButtonStyle()) }.padding() }.navigationTitle("Match Details").toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } } }.sheet(isPresented: $showingClaim) { OwnershipClaimView(item: match.foundReport, mode: .claim) } } }
    private func summary(_ item: ItemReport, _ label: String) -> some View { VStack(spacing: 8) { Text(label).font(AppTheme.Font.overline).foregroundStyle(.secondary); CategoryIcon(category: item.categoryEnum, size: 52); Text(item.name).font(AppTheme.Font.caption).multilineTextAlignment(.center).lineLimit(2) }.frame(maxWidth: .infinity).padding(12).background(Color(.secondarySystemGroupedBackground)).clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.md)) }
}

#Preview { MatchesView().modelContainer(for: [ItemReport.self, MatchRecord.self], inMemory: true) }
