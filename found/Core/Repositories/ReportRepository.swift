import Foundation
import SwiftData
import CoreLocation

struct ReportDraft: Sendable {
    var reportType: ReportType
    var name: String
    var category: ItemCategory
    var description: String
    var publicLocationName: String
    var privateCoordinate: CLLocationCoordinate2D?
    var publicCoordinate: CLLocationCoordinate2D?
    var campusPlaceID: String?
    var occurredAt: Date
    var photoData: Data?
    var thumbnailData: Data?
    var colorHint: String
    var detectedText: String
    var privateVerification: PrivateVerificationPayload?
}

@MainActor
final class ReportRepository {
    private let context: ModelContext
    init(context: ModelContext) { self.context = context }

    @discardableResult
    func create(_ draft: ReportDraft, ownerID: String = LocalIdentity.userID) throws -> ItemReport {
        let report = ItemReport(ownerID: ownerID, reportType: draft.reportType, name: draft.name.trimmed,
                                category: draft.category, itemDescription: draft.description.trimmed,
                                publicLocationName: draft.publicLocationName.trimmed,
                                privateCoordinate: draft.privateCoordinate, publicCoordinate: draft.publicCoordinate,
                                campusPlaceID: draft.campusPlaceID, occurredAt: draft.occurredAt,
                                photoData: draft.photoData, thumbnailData: draft.thumbnailData,
                                colorHint: draft.colorHint, detectedText: draft.detectedText)
        context.insert(report)
        if let privateVerification = draft.privateVerification {
            try PrivateVerificationStore.save(privateVerification, for: report.id)
        }
        try context.save()
        _ = try? ActivityRepository(context: context).record(type: .reportResolved, title: "Report posted", message: "Your \(report.reportTypeEnum.displayName.lowercased()) report is now visible on campus.", reportID: report.id)
        return report
    }

    func update(_ report: ItemReport, with draft: ReportDraft) throws {
        report.reportType = draft.reportType.rawValue; report.name = draft.name.trimmed; report.category = draft.category.rawValue
        report.itemDescription = draft.description.trimmed; report.publicLocationName = draft.publicLocationName.trimmed
        report.privateLatitude = draft.privateCoordinate?.latitude; report.privateLongitude = draft.privateCoordinate?.longitude
        report.publicLatitude = draft.publicCoordinate?.latitude; report.publicLongitude = draft.publicCoordinate?.longitude
        report.campusPlaceID = draft.campusPlaceID; report.occurredAt = draft.occurredAt
        report.photoData = draft.photoData; report.thumbnailData = draft.thumbnailData; report.colorHint = draft.colorHint
        report.detectedText = draft.detectedText; report.updatedAt = .now
        if let privateVerification = draft.privateVerification { try PrivateVerificationStore.save(privateVerification, for: report.id) }
        try context.save()
    }

    func delete(_ report: ItemReport) throws {
        PrivateVerificationStore.delete(for: report.id)
        let matches = try context.fetch(FetchDescriptor<MatchRecord>())
        for match in matches where match.lostReportID == report.id || match.foundReportID == report.id { context.delete(match) }
        context.delete(report)
        try context.save()
    }

    func resolve(_ report: ItemReport) throws {
        report.state = ReportState.resolved.rawValue; report.resolvedAt = .now; report.updatedAt = .now
        let matches = try context.fetch(FetchDescriptor<MatchRecord>())
        for match in matches where match.lostReportID == report.id || match.foundReportID == report.id { match.status = MatchStatus.resolved.rawValue; match.updatedAt = .now }
        try context.save()
        _ = try? ActivityRepository(context: context).record(type: .reportResolved, title: "Report resolved", message: "\(report.name) has been marked resolved.", reportID: report.id)
    }

    func reopen(_ report: ItemReport) throws {
        report.state = ReportState.active.rawValue; report.resolvedAt = nil; report.updatedAt = .now
        try context.save()
    }

    func reports(sort: ReportSort = .newest) throws -> [ItemReport] {
        let descriptor = FetchDescriptor<ItemReport>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        let rows = try context.fetch(descriptor)
        return sort == .newest ? rows : rows.sorted { ($0.coordinate?.distance(to: .init(latitude: 0, longitude: 0)) ?? .greatestFiniteMagnitude) < ($1.coordinate?.distance(to: .init(latitude: 0, longitude: 0)) ?? .greatestFiniteMagnitude) }
    }

    func report(id: UUID) throws -> ItemReport? {
        try context.fetch(FetchDescriptor<ItemReport>(predicate: #Predicate { $0.id == id })).first
    }

    func seedDemoIfNeeded() throws {
        let existingDemoIDs = Set(try context.fetch(FetchDescriptor<ItemReport>(predicate: #Predicate { $0.isDemo })).map(\.id))
        for seed in DemoData.reports {
            guard !existingDemoIDs.contains(seed.id) else { continue }
            let ownerID = seed.ownerID == "demo-current-user" ? LocalIdentity.userID : seed.ownerID
            context.insert(ItemReport(id: seed.id, ownerID: ownerID, reportType: seed.reportType, name: seed.name,
                                      category: seed.category, itemDescription: seed.description, publicLocationName: seed.locationName,
                                      privateCoordinate: seed.coordinate, publicCoordinate: LocationPrivacy.approximate(seed.coordinate),
                                      occurredAt: seed.occurredAt, createdAt: seed.createdAt, colorHint: seed.colorHint, isDemo: true))
        }
        let localDemoReportIDs = Set(DemoData.reports.filter { $0.ownerID == "demo-current-user" }.map(\.id))
        for report in try context.fetch(FetchDescriptor<ItemReport>(predicate: #Predicate { $0.isDemo })) where localDemoReportIDs.contains(report.id) {
            report.ownerID = LocalIdentity.userID
        }
        try context.save()
    }
}

enum ReportSort: String, CaseIterable { case newest, nearest, relevance }
