import Foundation
import SwiftData
import CoreLocation

@MainActor
final class ReturnArrangementRepository {
    private let context: ModelContext
    init(context: ModelContext) { self.context = context }
    @discardableResult
    func create(claimID: UUID, locationName: String, coordinate: CLLocationCoordinate2D?, scheduledAt: Date, notes: String) throws -> ReturnArrangement {
        let arrangement = ReturnArrangement(claimID: claimID, locationName: locationName, coordinate: coordinate, scheduledAt: scheduledAt, notes: notes)
        context.insert(arrangement); try context.save()
        _ = try? ActivityRepository(context: context).record(type: .pickupScheduled, title: "Pickup proposed", message: "Pickup at \(locationName) on \(scheduledAt.shortDateString).", claimID: claimID)
        return arrangement
    }
    func confirm(_ arrangement: ReturnArrangement) throws { arrangement.status = ReturnArrangementStatus.confirmed.rawValue; arrangement.updatedAt = .now; try context.save() }
    func complete(_ arrangement: ReturnArrangement, report: ItemReport) throws {
        arrangement.status = ReturnArrangementStatus.completed.rawValue; arrangement.updatedAt = .now
        report.state = ReportState.resolved.rawValue; report.resolvedAt = .now; report.updatedAt = .now; try context.save()
        _ = try? ActivityRepository(context: context).record(type: .returnCompleted, title: "Return completed", message: "\(report.name) was marked as handed over.", reportID: report.id, claimID: arrangement.claimID)
    }

    func sendMessage(claimID: UUID, body: String, senderID: String = LocalIdentity.userID) throws {
        let text = body.trimmed
        guard !text.isEmpty else { return }
        context.insert(CoordinationMessage(claimID: claimID, senderID: senderID, body: text))
        try context.save()
    }
}
