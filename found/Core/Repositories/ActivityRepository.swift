import Foundation
import SwiftData

@MainActor
final class ActivityRepository {
    private let context: ModelContext
    init(context: ModelContext) { self.context = context }
    @discardableResult
    func record(recipientID: String = LocalIdentity.userID, type: ActivityEventType, title: String, message: String, reportID: UUID? = nil, claimID: UUID? = nil) throws -> ActivityEvent {
        let event = ActivityEvent(recipientID: recipientID, type: type, title: title, message: message, relatedReportID: reportID, relatedClaimID: claimID)
        context.insert(event); try context.save()
        if recipientID == LocalIdentity.userID {
            NotificationService().scheduleActivity(type: type, title: title, message: message)
        }
        return event
    }
    func markRead(_ event: ActivityEvent) throws { event.isRead = true; try context.save() }
}
