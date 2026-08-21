import SwiftUI

// MARK: - ProfileView

struct ProfileView: View {

    @State private var notificationsEnabled: Bool = true
    @State private var locationEnabled: Bool = true
    @State private var showingAbout: Bool = false
    @State private var selectedItem: MockItemReport? = nil

    private let user = UserProfile.current
    private let myLostItems = MockData.lostItems
    private let myFoundItems = MockData.foundItems.prefix(2).map { $0 }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: AppTheme.Spacing.xl) {

                        // Profile Header
                        profileHeader

                        // Stats
                        statsSection

                        // My Reports
                        myReportsSection

                        // Settings
                        settingsSection

                        // About
                        aboutSection
                    }
                    .padding(.horizontal, AppTheme.Spacing.lg)
                    .padding(.vertical, AppTheme.Spacing.md)
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .sheet(item: $selectedItem) { item in
                ItemDetailView(item: item)
            }
            .sheet(isPresented: $showingAbout) {
                AboutView()
            }
        }
    }

    // MARK: - Profile Header

    private var profileHeader: some View {
        HStack(spacing: 16) {
            // Avatar
            ZStack {
                Circle()
                    .fill(Color(.tertiarySystemGroupedBackground))
                    .frame(width: 72, height: 72)
                Text(user.initials)
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(user.name)
                    .font(AppTheme.Font.title2)
                Text("Member since \(user.joinDateString)")
                    .font(AppTheme.Font.caption)
                    .foregroundStyle(.secondary)
                HStack(spacing: 6) {
                    Circle()
                        .fill(AppTheme.Color.highConfidence)
                        .frame(width: 7, height: 7)
                    Text("Active student")
                        .font(AppTheme.Font.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
        .padding(AppTheme.Spacing.md)
        .cardStyle()
    }

    // MARK: - Stats

    private var statsSection: some View {
        HStack(spacing: 10) {
            statCard(value: "\(myLostItems.count)", label: "Lost Reports", color: AppTheme.Color.lost)
            statCard(value: "\(myFoundItems.count)", label: "Found Reports", color: AppTheme.Color.found)
            statCard(value: "1", label: "Items Returned", color: AppTheme.Color.highConfidence)
        }
    }

    func statCard(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(color)
            Text(label)
                .font(AppTheme.Font.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .cardStyle()
    }

    // MARK: - My Reports

    private var myReportsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("My Reports")
                .font(AppTheme.Font.title3)

            VStack(spacing: 10) {
                if myLostItems.isEmpty && myFoundItems.isEmpty {
                    EmptyStateView.noLostItems
                        .frame(height: 140)
                } else {
                    ForEach((myLostItems + myFoundItems).prefix(4)) { item in
                        ItemCard(item: item)
                            .onTapGesture {
                                selectedItem = item
                            }
                    }
                }
            }
        }
    }

    // MARK: - Settings

    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("Settings")
                .font(AppTheme.Font.title3)

            VStack(spacing: 0) {
                settingsToggle(
                    icon: "bell.fill",
                    iconColor: .orange,
                    title: "Notifications",
                    subtitle: "Get alerted when matches are found",
                    binding: $notificationsEnabled
                )

                Divider().padding(.horizontal, 16)

                settingsToggle(
                    icon: "location.fill",
                    iconColor: .blue,
                    title: "Location",
                    subtitle: "Used only when reporting items",
                    binding: $locationEnabled
                )

                Divider().padding(.horizontal, 16)

                settingsRow(
                    icon: "hand.raised.fill",
                    iconColor: .purple,
                    title: "Privacy",
                    subtitle: "Manage your data"
                ) { }
            }
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.lg))
        }
    }

    func settingsToggle(
        icon: String,
        iconColor: Color,
        title: String,
        subtitle: String,
        binding: Binding<Bool>
    ) -> some View {
        HStack(spacing: 14) {
            settingsIconView(icon: icon, color: iconColor)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppTheme.Font.subheadline)
                    .fontWeight(.medium)
                Text(subtitle)
                    .font(AppTheme.Font.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Toggle("", isOn: binding)
                .labelsHidden()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    func settingsRow(
        icon: String,
        iconColor: Color,
        title: String,
        subtitle: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                settingsIconView(icon: icon, color: iconColor)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(AppTheme.Font.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(AppTheme.Font.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.quaternary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
    }

    func settingsIconView(icon: String, color: Color) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(color)
                .frame(width: 34, height: 34)
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.white)
        }
    }

    // MARK: - About

    private var aboutSection: some View {
        VStack(spacing: 0) {
            Button {
                showingAbout = true
            } label: {
                HStack {
                    Text("About Lost & Found")
                        .font(AppTheme.Font.subheadline)
                        .foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.quaternary)
                }
                .padding(16)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.lg))
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - UserProfile

struct UserProfile {
    let name: String
    let joinDate: Date

    var initials: String {
        let parts = name.split(separator: " ")
        return parts.prefix(2).compactMap { $0.first }.map(String.init).joined()
    }

    var joinDateString: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "MMMM yyyy"
        return fmt.string(from: joinDate)
    }

    static let current = UserProfile(
        name: "Aditya Shukla",
        joinDate: Calendar.current.date(byAdding: .month, value: -3, to: Date())!
    )
}

// MARK: - AboutView

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: AppTheme.Spacing.xl) {

                        // Logo area
                        VStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 24)
                                    .fill(Color(.secondarySystemGroupedBackground))
                                    .frame(width: 90, height: 90)
                                Image(systemName: "sparkles")
                                    .font(.system(size: 42, weight: .thin))
                                    .symbolRenderingMode(.hierarchical)
                                    .foregroundStyle(Color.accentColor)
                            }
                            Text("Lost & Found")
                                .font(AppTheme.Font.title1)
                            Text("Version 1.0")
                                .font(AppTheme.Font.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, AppTheme.Spacing.lg)

                        // About text
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                            aboutParagraph(
                                icon: "heart.fill",
                                color: .red,
                                title: "Our Mission",
                                body: "Lost & Found helps students on campus reconnect with their belongings — quickly, safely, and privately."
                            )
                            aboutParagraph(
                                icon: "lock.shield.fill",
                                color: .blue,
                                title: "Privacy First",
                                body: "We never publicly share personal contact information, exact locations, or sensitive identifying details."
                            )
                            aboutParagraph(
                                icon: "sparkles",
                                icon2: "cpu.fill",
                                color: AppTheme.Color.highConfidence,
                                title: "Smart Matching",
                                body: "Our matching engine analyzes category, description, color, location and time to surface likely matches automatically."
                            )
                        }
                        .padding(.horizontal, AppTheme.Spacing.lg)

                        Text("Built with ♥ for the Apple Developer Academy")
                            .font(AppTheme.Font.caption)
                            .foregroundStyle(.tertiary)
                            .multilineTextAlignment(.center)
                            .padding(.bottom, AppTheme.Spacing.xl)
                    }
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    func aboutParagraph(icon: String, icon2: String? = nil, color: Color, title: String, body: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.12))
                    .frame(width: 42, height: 42)
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(color)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(AppTheme.Font.headline)
                Text(body)
                    .font(AppTheme.Font.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

#Preview {
    ProfileView()
}
