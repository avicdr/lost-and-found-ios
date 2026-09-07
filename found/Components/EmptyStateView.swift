import SwiftUI

// MARK: - EmptyStateView

struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    var actionTitle: String? = nil
    var onAction: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            Spacer()

            Image(systemName: icon)
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(.quaternary)
                .symbolRenderingMode(.hierarchical)
                .padding(.bottom, 4)

            VStack(spacing: 6) {
                Text(title)
                    .font(AppTheme.Font.title3)
                    .multilineTextAlignment(.center)

                Text(subtitle)
                    .font(AppTheme.Font.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, AppTheme.Spacing.xl)
            }

            if let actionTitle, let onAction {
                Button(actionTitle, action: onAction)
                    .buttonStyle(PrimaryButtonStyle())
                    .padding(.horizontal, AppTheme.Spacing.xl)
                    .padding(.top, AppTheme.Spacing.sm)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(subtitle)")
    }
}

// MARK: - Predefined Empty States

extension EmptyStateView {
    static var noLostItems: EmptyStateView {
        EmptyStateView(
            icon: "checkmark.seal",
            title: "Nothing lost here.",
            subtitle: "Hopefully it stays that way."
        )
    }

    static var noFoundItems: EmptyStateView {
        EmptyStateView(
            icon: "mappin.and.ellipse",
            title: "Nothing found nearby.",
            subtitle: "Check back later — new items are added often."
        )
    }

    static var noMatches: EmptyStateView {
        EmptyStateView(
            icon: "sparkles",
            title: "No matches yet.",
            subtitle: "We'll let you know if something looks promising."
        )
    }

    static var searchNoResults: EmptyStateView {
        EmptyStateView(
            icon: "magnifyingglass",
            title: "No results found.",
            subtitle: "Try different keywords or adjust your filters."
        )
    }

    static var locationUnavailable: EmptyStateView {
        EmptyStateView(
            icon: "location.slash",
            title: "Location access is off.",
            subtitle: "Location access is turned off. You can still enter the location manually."
        )
    }
}
