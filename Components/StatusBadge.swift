import SwiftUI

// MARK: - StatusBadge
/// Displays Lost / Found / Matched / Returned in a small pill badge

struct StatusBadge: View {
    let reportType: ReportType
    var compact: Bool = false

    private var backgroundColor: Color {
        AppTheme.color(for: reportType).opacity(0.15)
    }

    private var foregroundColor: Color {
        AppTheme.color(for: reportType)
    }

    var body: some View {
        Text(reportType.displayName.uppercased())
            .font(compact ? AppTheme.Font.overline : AppTheme.Font.caption)
            .foregroundStyle(foregroundColor)
            .padding(.horizontal, compact ? 8 : 10)
            .padding(.vertical, compact ? 3 : 4)
            .background(backgroundColor)
            .clipShape(Capsule())
    }
}

// MARK: - ItemStatusBadge

struct ItemStatusBadge: View {
    let status: ItemStatus

    private var color: Color {
        switch status {
        case .active: return .secondary
        case .matched: return AppTheme.Color.mediumConfidence
        case .returned: return AppTheme.Color.highConfidence
        case .closed: return .secondary
        }
    }

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text(status.displayName)
                .font(AppTheme.Font.caption)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - ConfidenceBadge

struct ConfidenceBadge: View {
    let confidence: Double

    private var tier: ConfidenceTier {
        switch confidence {
        case 0.75...: return .high
        case 0.50..<0.75: return .medium
        default: return .low
        }
    }

    var body: some View {
        Text("\(Int(confidence * 100))%")
            .font(AppTheme.Font.caption)
            .fontWeight(.bold)
            .foregroundStyle(AppTheme.color(for: tier))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(AppTheme.color(for: tier).opacity(0.15))
            .clipShape(Capsule())
    }
}

// MARK: - CategoryIcon

struct CategoryIcon: View {
    let category: ItemCategory
    var size: CGFloat = 40

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.28)
                .fill(Color(.tertiarySystemGroupedBackground))
                .frame(width: size, height: size)

            Image(systemName: category.icon)
                .font(.system(size: size * 0.42, weight: .medium))
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - SectionHeader

struct SectionHeader: View {
    let title: String
    var action: String? = nil
    var onAction: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(AppTheme.Font.title3)

            Spacer()

            if let action, let onAction {
                Button(action, action: onAction)
                    .font(AppTheme.Font.callout)
                    .foregroundStyle(Color.accentColor)
            }
        }
    }
}
