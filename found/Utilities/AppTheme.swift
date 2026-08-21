import SwiftUI

// MARK: - App Design Tokens
// All colors, typography, and spacing constants live here.
// Use semantic system colors to support dark mode automatically.

enum AppTheme {

    // MARK: - Colors

    enum Color {
        /// Primary accent — deep indigo
        static let accent = SwiftUI.Color.accentColor

        /// Lost item accent — warm amber
        static let lost = SwiftUI.Color(hue: 0.09, saturation: 0.85, brightness: 0.95)

        /// Found item accent — cool teal
        static let found = SwiftUI.Color(hue: 0.50, saturation: 0.75, brightness: 0.80)

        /// High confidence match — green
        static let highConfidence = SwiftUI.Color(hue: 0.37, saturation: 0.70, brightness: 0.75)

        /// Medium confidence match — amber
        static let mediumConfidence = SwiftUI.Color(hue: 0.12, saturation: 0.85, brightness: 0.92)

        /// Low confidence match — muted gray-blue
        static let lowConfidence = SwiftUI.Color.secondary

        /// Card background
        static let cardBackground = SwiftUI.Color(.secondarySystemGroupedBackground)

        /// Page background
        static let pageBackground = SwiftUI.Color(.systemGroupedBackground)
    }

    // MARK: - Typography

    enum Font {
        static let largeTitle = SwiftUI.Font.system(size: 40, weight: .bold, design: .rounded)
        static let title1 = SwiftUI.Font.system(size: 28, weight: .bold, design: .rounded)
        static let title2 = SwiftUI.Font.system(size: 22, weight: .semibold, design: .rounded)
        static let title3 = SwiftUI.Font.system(size: 20, weight: .semibold, design: .default)
        static let headline = SwiftUI.Font.system(size: 17, weight: .semibold)
        static let body = SwiftUI.Font.system(size: 17, weight: .regular)
        static let callout = SwiftUI.Font.system(size: 16, weight: .regular)
        static let subheadline = SwiftUI.Font.system(size: 15, weight: .regular)
        static let caption = SwiftUI.Font.system(size: 12, weight: .medium)
        static let overline = SwiftUI.Font.system(size: 11, weight: .bold)
    }

    // MARK: - Spacing

    enum Spacing {
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 8
        static let sm: CGFloat = 12
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }

    // MARK: - Corner Radii

    enum Radius {
        static let sm: CGFloat = 12
        static let md: CGFloat = 18
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
    }

    // MARK: - Helpers

    static func color(for reportType: ReportType) -> SwiftUI.Color {
        reportType == .lost ? Color.lost : Color.found
    }

    static func color(for tier: ConfidenceTier) -> SwiftUI.Color {
        switch tier {
        case .high: return Color.highConfidence
        case .medium: return Color.mediumConfidence
        case .low: return Color.lowConfidence
        }
    }
}

// MARK: - View Modifiers

struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(AppTheme.Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.lg))
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    var isDestructive: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppTheme.Font.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 17)
            .background(isDestructive ? SwiftUI.Color.red : SwiftUI.Color.primary)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.md))
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(duration: 0.2), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppTheme.Font.headline)
            .foregroundStyle(.primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 17)
            .background(AppTheme.Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.md))
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(duration: 0.2), value: configuration.isPressed)
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardStyle())
    }
}
