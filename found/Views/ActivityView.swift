import SwiftUI
import SwiftData

struct ActivityView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ActivityEvent.createdAt, order: .reverse) private var events: [ActivityEvent]
    private var myEvents: [ActivityEvent] { events.filter { $0.recipientID == LocalIdentity.userID } }
    var body: some View { NavigationStack { Group { if myEvents.isEmpty { EmptyStateView(icon: "bell", title: "No activity yet.", subtitle: "Matches, claims, and return updates will appear here.") } else { List(myEvents) { event in Button { try? ActivityRepository(context: modelContext).markRead(event) } label: { HStack(alignment: .top, spacing: 12) { Image(systemName: icon(for: event.typeEnum)).foregroundStyle(color(for: event.typeEnum)).frame(width: 24); VStack(alignment: .leading, spacing: 3) { Text(event.title).font(AppTheme.Font.headline); Text(event.message).font(AppTheme.Font.caption).foregroundStyle(.secondary); Text(event.createdAt.relativeDescription).font(AppTheme.Font.caption).foregroundStyle(.tertiary) }; Spacer(); if !event.isRead { Circle().fill(Color.accentColor).frame(width: 8, height: 8) } } }.buttonStyle(.plain) } } }.navigationTitle("Activity").navigationBarTitleDisplayMode(.large) } }
    private func icon(for type: ActivityEventType) -> String { switch type { case .potentialMatch, .strongMatch: "sparkles"; case .claimSubmitted, .verificationRequired: "hand.raised.fill"; case .claimVerified: "checkmark.seal.fill"; case .claimRejected: "xmark.shield.fill"; case .pickupScheduled, .pickupReminder: "calendar"; case .returnCompleted, .reportResolved: "checkmark.circle.fill" } }
    private func color(for type: ActivityEventType) -> Color { switch type { case .claimRejected: .orange; case .returnCompleted, .claimVerified: AppTheme.Color.highConfidence; default: Color.accentColor } }
}
