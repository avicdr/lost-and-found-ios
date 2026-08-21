import SwiftUI

// MARK: - ItemCard
/// Used in the Home feed, Explore list, and Profile screens.

struct ItemCard: View {
    let item: MockItemReport
    var showDistance: Bool = false

    var body: some View {
        HStack(spacing: 14) {

            // Thumbnail
            itemThumbnail

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(AppTheme.Font.headline)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    StatusBadge(reportType: item.reportType, compact: true)
                    Text("·")
                        .foregroundStyle(.quaternary)
                    Text(item.category.rawValue)
                        .font(AppTheme.Font.caption)
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 4) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                    Text(item.approximateLocation)
                        .font(AppTheme.Font.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Text(item.date.relativeDescription)
                    .font(AppTheme.Font.caption)
                    .foregroundStyle(.tertiary)
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.quaternary)
        }
        .padding(16)
        .cardStyle()
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(item.reportType.displayName): \(item.name). \(item.category.rawValue). \(item.approximateLocation). \(item.date.relativeDescription)")
    }

    @ViewBuilder
    private var itemThumbnail: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.tertiarySystemGroupedBackground))
                .frame(width: 60, height: 60)

            if let data = item.photoData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            } else {
                Image(systemName: item.category.icon)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(AppTheme.color(for: item.reportType).opacity(0.7))
            }
        }
    }
}

// MARK: - MatchCard

struct MatchCard: View {
    let match: ItemMatch

    var body: some View {
        HStack(spacing: 14) {

            // Item thumbnail (lost item)
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(.tertiarySystemGroupedBackground))
                    .frame(width: 60, height: 60)
                Image(systemName: match.lostReport.category.icon)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(AppTheme.Color.highConfidence.opacity(0.8))
            }

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 6) {
                    Text("Possible Match")
                        .font(AppTheme.Font.overline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    ConfidenceBadge(confidence: match.confidence)
                }

                Text(match.foundReport.name)
                    .font(AppTheme.Font.headline)
                    .lineLimit(1)

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
                        if reason.icon == "checkmark.circle.fill" {
                            Image(systemName: reason.icon)
                                .font(.system(size: 11))
                                .foregroundStyle(AppTheme.Color.highConfidence)
                        }
                    }
                    Text("\(match.reasons.filter { $0.icon == "checkmark.circle.fill" }.count) matching factors")
                        .font(AppTheme.Font.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(16)
        .cardStyle()
        .contentShape(Rectangle())
    }
}

// MARK: - SkeletonCard

struct SkeletonCard: View {
    @State private var animating = false

    var body: some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 14)
                .fill(skeletonColor)
                .frame(width: 60, height: 60)

            VStack(alignment: .leading, spacing: 8) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(skeletonColor)
                    .frame(height: 14)
                    .frame(maxWidth: 180)

                RoundedRectangle(cornerRadius: 6)
                    .fill(skeletonColor)
                    .frame(height: 11)
                    .frame(maxWidth: 120)

                RoundedRectangle(cornerRadius: 6)
                    .fill(skeletonColor)
                    .frame(height: 11)
                    .frame(maxWidth: 100)
            }
            Spacer()
        }
        .padding(16)
        .cardStyle()
        .opacity(animating ? 0.5 : 1.0)
        .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: animating)
        .onAppear { animating = true }
        .accessibilityHidden(true)
    }

    private var skeletonColor: Color {
        Color(.tertiarySystemGroupedBackground)
    }
}
