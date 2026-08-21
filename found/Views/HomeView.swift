import SwiftUI

// MARK: - HomeView

struct HomeView: View {

    @Binding var selectedTab: AppTab
    @State private var showingReportLost = false
    @State private var showingReportFound = false
    @State private var selectedItem: MockItemReport? = nil
    @State private var selectedMatch: ItemMatch? = nil

    private let matchingService = MatchingService()

    private var sampleMatches: [ItemMatch] { MockData.sampleMatches }
    private var recentItems: [MockItemReport] { Array(MockData.allItems.prefix(6)) }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.xl) {

                        // MARK: Header
                        headerSection
                            .padding(.horizontal, AppTheme.Spacing.lg)
                            .padding(.top, AppTheme.Spacing.sm)

                        // MARK: Action Cards
                        actionCardsSection
                            .padding(.horizontal, AppTheme.Spacing.lg)

                        // MARK: Possible Matches
                        if !sampleMatches.isEmpty {
                            matchesSection
                        }

                        // MARK: Recent Activity
                        recentSection
                    }
                    .padding(.bottom, AppTheme.Spacing.xl)
                }
                .scrollIndicators(.hidden)
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingReportLost) {
                ReportItemView(mode: .lost)
            }
            .sheet(isPresented: $showingReportFound) {
                ReportItemView(mode: .found)
            }
            .sheet(item: $selectedItem) { item in
                ItemDetailView(item: item)
            }
            .sheet(item: $selectedMatch) { match in
                MatchDetailView(match: match)
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Lost & Found")
                .font(.system(size: 38, weight: .bold, design: .rounded))

            Text("Find what matters. Return what doesn't belong to you.")
                .font(AppTheme.Font.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Action Cards

    private var actionCardsSection: some View {
        VStack(spacing: 12) {
            HomeActionCard(
                icon: "magnifyingglass",
                title: "Lost Something?",
                subtitle: "Tell us what you're looking for.",
                buttonTitle: "Report Lost Item",
                accentColor: AppTheme.Color.lost
            ) {
                showingReportLost = true
            }

            HomeActionCard(
                icon: "hand.raised.fill",
                title: "Found Something?",
                subtitle: "Help someone get it back.",
                buttonTitle: "Report Found Item",
                accentColor: AppTheme.Color.found
            ) {
                showingReportFound = true
            }
        }
    }

    // MARK: - Matches Section

    private var matchesSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            SectionHeader(title: "Possible Matches", action: "See All") {
                selectedTab = .matches
            }
            .padding(.horizontal, AppTheme.Spacing.lg)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(sampleMatches) { match in
                        CompactMatchCard(match: match)
                            .frame(width: 280)
                            .onTapGesture {
                                selectedMatch = match
                            }
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.lg)
            }
        }
    }

    // MARK: - Recent Section

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            SectionHeader(title: "Recent Activity", action: "See All") {
                selectedTab = .explore
            }
            .padding(.horizontal, AppTheme.Spacing.lg)

            if recentItems.isEmpty {
                EmptyStateView(
                    icon: "clock",
                    title: "No recent activity.",
                    subtitle: "Lost and found items will appear here."
                )
                .frame(height: 160)
            } else {
                VStack(spacing: 10) {
                    ForEach(recentItems) { item in
                        ItemCard(item: item)
                            .onTapGesture {
                                selectedItem = item
                            }
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.lg)
            }
        }
    }
}

// MARK: - HomeActionCard

struct HomeActionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let buttonTitle: String
    let accentColor: Color
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(accentColor.opacity(0.15))
                            .frame(width: 52, height: 52)
                        Image(systemName: icon)
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(accentColor)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text(title)
                            .font(AppTheme.Font.title3)
                            .foregroundStyle(.primary)

                        Text(subtitle)
                            .font(AppTheme.Font.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
                }

                HStack {
                    Text(buttonTitle)
                        .font(AppTheme.Font.headline)
                        .foregroundStyle(.white)

                    Spacer()

                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.8))
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 14)
                .background(accentColor)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.md))
            }
            .padding(18)
            .cardStyle()
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .animation(.spring(duration: 0.2), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .accessibilityLabel(title)
        .accessibilityHint("Tap to \(buttonTitle.lowercased())")
    }
}

// MARK: - CompactMatchCard

struct CompactMatchCard: View {
    let match: ItemMatch

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Possible match")
                    .font(AppTheme.Font.overline)
                    .foregroundStyle(.secondary)
                Spacer()
                ConfidenceBadge(confidence: match.confidence)
            }

            Text(match.foundReport.name)
                .font(AppTheme.Font.headline)
                .lineLimit(2)

            HStack(spacing: 4) {
                Image(systemName: "location.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
                Text("Found near \(match.foundReport.approximateLocation)")
                    .font(AppTheme.Font.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            HStack(spacing: 6) {
                ForEach(match.reasons.prefix(2)) { reason in
                    HStack(spacing: 3) {
                        Image(systemName: reason.icon)
                            .font(.system(size: 10))
                            .foregroundStyle(reason.icon.contains("checkmark") ? AppTheme.Color.highConfidence : .secondary)
                        Text(reason.text)
                            .font(AppTheme.Font.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack {
                Spacer()
                Text("View Match")
                    .font(AppTheme.Font.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.accentColor)
                Image(systemName: "arrow.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Color.accentColor)
            }
        }
        .padding(16)
        .cardStyle()
    }
}

#Preview {
    HomeView(selectedTab: .constant(.home))
}
