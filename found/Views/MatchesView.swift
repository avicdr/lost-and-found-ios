import SwiftUI

// MARK: - MatchesView

struct MatchesView: View {

    @State private var selectedMatch: ItemMatch? = nil
    private let matches = MockData.sampleMatches

    private var highConfidence: [ItemMatch] {
        matches.filter { $0.confidenceTier == .high }
    }

    private var possibleMatches: [ItemMatch] {
        matches.filter { $0.confidenceTier == .medium }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()

                if matches.isEmpty {
                    EmptyStateView.noMatches
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.xl) {

                            if !highConfidence.isEmpty {
                                matchSection(
                                    title: "High Confidence",
                                    icon: "sparkles",
                                    iconColor: AppTheme.Color.highConfidence,
                                    items: highConfidence
                                )
                            }

                            if !possibleMatches.isEmpty {
                                matchSection(
                                    title: "Possible Matches",
                                    icon: "questionmark.circle.fill",
                                    iconColor: AppTheme.Color.mediumConfidence,
                                    items: possibleMatches
                                )
                            }
                        }
                        .padding(.horizontal, AppTheme.Spacing.lg)
                        .padding(.vertical, AppTheme.Spacing.md)
                    }
                    .scrollIndicators(.hidden)
                }
            }
            .navigationTitle("Matches")
            .navigationBarTitleDisplayMode(.large)
            .sheet(item: $selectedMatch) { match in
                MatchDetailView(match: match)
            }
        }
    }

    // MARK: - Match Section

    private func matchSection(
        title: String,
        icon: String,
        iconColor: Color,
        items: [ItemMatch]
    ) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundStyle(iconColor)
                Text(title)
                    .font(AppTheme.Font.title3)
            }

            VStack(spacing: 10) {
                ForEach(items) { match in
                    FullMatchCard(match: match)
                        .onTapGesture {
                            selectedMatch = match
                        }
                        .transition(.opacity.combined(with: .move(edge: .leading)))
                }
            }
        }
        .animation(.spring(duration: 0.4), value: items.count)
    }
}

// MARK: - FullMatchCard

struct FullMatchCard: View {
    let match: ItemMatch
    @State private var appeared = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {

            // Header
            HStack(spacing: 12) {
                CategoryIcon(category: match.lostReport.category, size: 48)

                VStack(alignment: .leading, spacing: 3) {
                    Text("Possible Match")
                        .font(AppTheme.Font.overline)
                        .foregroundStyle(.secondary)
                    Text(match.foundReport.name)
                        .font(AppTheme.Font.headline)
                        .lineLimit(1)
                    Text("Lost: \(match.lostReport.name)")
                        .font(AppTheme.Font.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                ConfidenceBadge(confidence: match.confidence)
            }

            // Location & date
            HStack(spacing: 14) {
                Label(match.foundReport.approximateLocation, systemImage: "location.fill")
                    .font(AppTheme.Font.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                Spacer()

                Text(match.foundReport.date.relativeDescription)
                    .font(AppTheme.Font.caption)
                    .foregroundStyle(.tertiary)
            }

            // Reasons
            VStack(alignment: .leading, spacing: 6) {
                ForEach(match.reasons.prefix(3)) { reason in
                    HStack(spacing: 8) {
                        Image(systemName: reason.icon)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(reason.icon.contains("checkmark") ? AppTheme.Color.highConfidence : .secondary)
                            .frame(width: 16)
                        Text(reason.text)
                            .font(AppTheme.Font.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }

            // CTA
            HStack {
                Spacer()
                Text("View Match")
                    .font(AppTheme.Font.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.accentColor)
                Image(systemName: "arrow.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.accentColor)
            }
        }
        .padding(16)
        .cardStyle()
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 16)
        .onAppear {
            withAnimation(.spring(duration: 0.45, bounce: 0.2)) {
                appeared = true
            }
        }
    }
}

// MARK: - MatchDetailView

struct MatchDetailView: View {
    let match: ItemMatch
    @Environment(\.dismiss) private var dismiss
    @State private var showingClaimFlow = false
    @State private var notificationService = NotificationService()

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {

                        // Match confidence header
                        confidenceHeader

                        // Items comparison
                        itemsComparison

                        // Why it matches
                        whyItMatches

                        // Actions
                        actionButtons
                    }
                    .padding(AppTheme.Spacing.lg)
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle("Match Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .sheet(isPresented: $showingClaimFlow) {
                OwnershipClaimView(item: match.foundReport, mode: .claim)
            }
        }
    }

    // MARK: - Confidence Header

    private var confidenceHeader: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            CategoryIcon(category: match.lostReport.category, size: 56)

            VStack(alignment: .leading, spacing: 4) {
                Text("Possible Match")
                    .font(AppTheme.Font.overline)
                    .foregroundStyle(.secondary)
                Text(match.foundReport.name)
                    .font(AppTheme.Font.title2)
                HStack(spacing: 8) {
                    ConfidenceBadge(confidence: match.confidence)
                    Text("confidence")
                        .font(AppTheme.Font.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(AppTheme.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.color(for: match.confidenceTier).opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.lg))
    }

    // MARK: - Items Comparison

    private var itemsComparison: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("ITEMS COMPARED")
                .font(AppTheme.Font.overline)
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                itemSummaryCard(
                    item: match.lostReport,
                    label: "Your Lost Item"
                )

                Image(systemName: "arrow.left.arrow.right")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.secondary)

                itemSummaryCard(
                    item: match.foundReport,
                    label: "Found Item"
                )
            }
        }
    }

    func itemSummaryCard(item: MockItemReport, label: String) -> some View {
        VStack(spacing: 8) {
            Text(label)
                .font(AppTheme.Font.overline)
                .foregroundStyle(.secondary)

            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.tertiarySystemGroupedBackground))
                    .frame(height: 70)
                Image(systemName: item.category.icon)
                    .font(.system(size: 28, weight: .light))
                    .foregroundStyle(.secondary)
            }

            Text(item.name)
                .font(AppTheme.Font.caption)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.md))
    }

    // MARK: - Why It Matches

    private var whyItMatches: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("WHY WE THINK THIS MATCHES")
                .font(AppTheme.Font.overline)
                .foregroundStyle(.secondary)

            VStack(spacing: 0) {
                ForEach(Array(match.reasons.enumerated()), id: \.element.id) { index, reason in
                    HStack(spacing: 12) {
                        Image(systemName: reason.icon)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(reason.icon.contains("checkmark") ? AppTheme.Color.highConfidence : .secondary)
                            .frame(width: 22)

                        Text(reason.text)
                            .font(AppTheme.Font.subheadline)
                            .fixedSize(horizontal: false, vertical: true)

                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)

                    if index < match.reasons.count - 1 {
                        Divider().padding(.horizontal, 16)
                    }
                }
            }
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.lg))
        }
    }

    // MARK: - Actions

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button {
                showingClaimFlow = true
            } label: {
                Label("This is mine", systemImage: "hand.raised.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryButtonStyle())

            Button {
                dismiss()
            } label: {
                Text("Not my item")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(SecondaryButtonStyle())
        }
    }
}

#Preview {
    MatchesView()
}
