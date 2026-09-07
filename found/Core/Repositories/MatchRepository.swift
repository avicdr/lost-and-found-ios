import Foundation
import SwiftData

@MainActor
final class MatchRepository {
    private let context: ModelContext
    private let matchingService: MatchingServiceProtocol
    init(context: ModelContext, matchingService: MatchingServiceProtocol = MatchingService()) {
        self.context = context; self.matchingService = matchingService
    }

    func refreshMatches() throws {
        let reports = try context.fetch(FetchDescriptor<ItemReport>())
        let lost = reports.filter { $0.reportTypeEnum == .lost && $0.isActive }
        let found = reports.filter { $0.reportTypeEnum == .found && $0.isActive }
        let existing = try context.fetch(FetchDescriptor<MatchRecord>())
        let validPairs = Set(lost.flatMap { left in found.map { "\(left.id.uuidString):\($0.id.uuidString)" } })
        for stale in existing where !validPairs.contains("\(stale.lostReportID.uuidString):\(stale.foundReportID.uuidString)") && stale.statusEnum != .resolved { context.delete(stale) }
        for lostReport in lost {
            for foundReport in found {
                let key = "\(lostReport.id.uuidString):\(foundReport.id.uuidString)"
                guard let result = matchingService.score(lost: lostReport, found: foundReport) else {
                    if let prior = existing.first(where: { "\($0.lostReportID.uuidString):\($0.foundReportID.uuidString)" == key }), prior.statusEnum != .resolved { context.delete(prior) }
                    continue
                }
                if let record = existing.first(where: { "\($0.lostReportID.uuidString):\($0.foundReportID.uuidString)" == key }) {
                    guard ![.claimSubmitted, .verified, .resolved].contains(record.statusEnum) else { continue }
                    record.score = result.score; record.status = result.status.rawValue; record.factorsData = try JSONEncoder().encode(result.factors); record.updatedAt = .now
                } else {
                    let record = MatchRecord(lostReportID: result.lostReportID, foundReportID: result.foundReportID, score: result.score, status: result.status, factors: result.factors)
                    context.insert(record)
                    let eventType: ActivityEventType = result.status == .strong ? .strongMatch : .potentialMatch
                    _ = try? ActivityRepository(context: context).record(recipientID: lostReport.ownerID, type: eventType,
                        title: result.status == .strong ? "Strong match detected" : "New potential match",
                        message: "\(foundReport.name) may match your lost \(lostReport.name).", reportID: lostReport.id)
                }
            }
        }
        try context.save()
    }

    func matches() throws -> [MatchRecord] {
        try context.fetch(FetchDescriptor<MatchRecord>(sortBy: [SortDescriptor(\.score, order: .reverse)]))
    }

    func report(for id: UUID) throws -> ItemReport? {
        try context.fetch(FetchDescriptor<ItemReport>(predicate: #Predicate { $0.id == id })).first
    }
}
