import SwiftUI
import SwiftData

struct ProfileView: View {
    @Query(sort: \ItemReport.createdAt, order: .reverse) private var reports: [ItemReport]
    @Query private var claims: [ClaimRequest]
    @AppStorage("lostandfound.notifications-enabled") private var notificationsEnabled = true
    @AppStorage("lostandfound.demo-mode") private var demoMode = false
    @State private var selectedItem: ItemReport?
    @State private var showingAbout = false
    @State private var notificationService = NotificationService()
    @State private var showingActivity = false

    private var myReports: [ItemReport] { reports.filter { $0.ownerID == LocalIdentity.userID } }
    private var activeClaims: [ClaimRequest] { claims.filter { $0.claimantID == LocalIdentity.userID && [.pending, .needsReview].contains($0.statusEnum) } }
    private var lostCount: Int { myReports.filter { $0.reportTypeEnum == .lost }.count }
    private var foundCount: Int { myReports.filter { $0.reportTypeEnum == .found }.count }
    private var resolvedCount: Int { myReports.filter { $0.stateEnum == .resolved }.count }

    var body: some View { NavigationStack { ZStack { Color(.systemGroupedBackground).ignoresSafeArea(); ScrollView { VStack(spacing: AppTheme.Spacing.xl) {
        profileHeader; statsSection; reportsSection; settingsSection; aboutSection
    }.padding(.horizontal, AppTheme.Spacing.lg).padding(.vertical, AppTheme.Spacing.md) }.scrollIndicators(.hidden) }.navigationTitle("Profile").navigationBarTitleDisplayMode(.large).sheet(item: $selectedItem) { ItemDetailView(item: $0) }.sheet(isPresented: $showingAbout) { AboutView() } } }

    private var profileHeader: some View { HStack(spacing: 16) { ZStack { Circle().fill(Color(.tertiarySystemGroupedBackground)).frame(width: 72, height: 72); Text("ME").font(.system(size: 22, weight: .semibold, design: .rounded)).foregroundStyle(.secondary) }; VStack(alignment: .leading, spacing: 4) { Text("Campus Member").font(AppTheme.Font.title2); Text(resolvedCount > 0 ? "Trusted contributor · \(resolvedCount) successful return\(resolvedCount == 1 ? "" : "s")" : "Local-first profile on this device").font(AppTheme.Font.caption).foregroundStyle(.secondary); Label("Privacy protected", systemImage: "lock.shield.fill").font(AppTheme.Font.caption).foregroundStyle(.secondary) }; Spacer() }.padding(AppTheme.Spacing.md).cardStyle() }
    private var statsSection: some View { HStack(spacing: 10) { statCard("\(lostCount)", "Lost Reports", AppTheme.Color.lost); statCard("\(foundCount)", "Found Reports", AppTheme.Color.found); statCard("\(resolvedCount)", "Resolved", AppTheme.Color.highConfidence) } }
    private func statCard(_ value: String, _ label: String, _ color: Color) -> some View { VStack(spacing: 4) { Text(value).font(.system(size: 28, weight: .bold, design: .rounded)).foregroundStyle(color); Text(label).font(AppTheme.Font.caption).foregroundStyle(.secondary).multilineTextAlignment(.center) }.frame(maxWidth: .infinity).padding(.vertical, 16).cardStyle() }
    private var reportsSection: some View { VStack(alignment: .leading, spacing: 10) { HStack { Text("My Reports").font(AppTheme.Font.title3); Spacer(); Text("\(activeClaims.count) active claims").font(AppTheme.Font.caption).foregroundStyle(.secondary) }; if myReports.isEmpty { EmptyStateView(icon: "tray", title: "No reports yet.", subtitle: "Reports you create will appear here.").frame(height: 160) } else { ForEach(myReports.prefix(5)) { report in ItemCard(item: report).onTapGesture { selectedItem = report } } } } }
    private var settingsSection: some View { VStack(alignment: .leading, spacing: 10) { Text("Settings").font(AppTheme.Font.title3); VStack(spacing: 0) {
        Toggle(isOn: $notificationsEnabled) { Label("Match & return notifications", systemImage: "bell.fill") }.padding(16).onChange(of: notificationsEnabled) { _, enabled in if enabled { Task { await notificationService.requestPermission() } } }; Divider().padding(.horizontal, 16)
        Toggle(isOn: $demoMode) { Label("Portfolio Sample Data", systemImage: "photo.on.rectangle") }.padding(16); Divider().padding(.horizontal, 16)
        Label("Exact locations and verification answers remain private", systemImage: "lock.shield").font(AppTheme.Font.caption).foregroundStyle(.secondary).padding(16)
    }.background(Color(.secondarySystemGroupedBackground)).clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.lg)) } }
    private var aboutSection: some View { VStack(spacing: 10) { Button { showingActivity = true } label: { HStack { Label("Activity", systemImage: "bell").font(AppTheme.Font.subheadline).foregroundStyle(.primary); Spacer(); Image(systemName: "chevron.right").foregroundStyle(.quaternary) }.padding(16).background(Color(.secondarySystemGroupedBackground)).clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.lg)) }.buttonStyle(.plain); Button { showingAbout = true } label: { HStack { Text("About Lost & Found").font(AppTheme.Font.subheadline).foregroundStyle(.primary); Spacer(); Image(systemName: "chevron.right").foregroundStyle(.quaternary) }.padding(16).background(Color(.secondarySystemGroupedBackground)).clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.lg)) }.buttonStyle(.plain) }.sheet(isPresented: $showingActivity) { ActivityView() } }
}

struct AboutView: View { @Environment(\.dismiss) private var dismiss
    var body: some View { NavigationStack { VStack(spacing: 18) { Image(systemName: "magnifyingglass.circle.fill").font(.system(size: 44)).foregroundStyle(Color.accentColor); Text("Lost & Found").font(AppTheme.Font.title1); Text("A private, local-first campus lost and found network.").font(AppTheme.Font.callout).foregroundStyle(.secondary).multilineTextAlignment(.center).padding(.horizontal, 28); Spacer() }.padding().navigationTitle("About").toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } } } }
}
