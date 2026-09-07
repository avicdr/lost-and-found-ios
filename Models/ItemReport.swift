import Foundation
import SwiftData
import CoreLocation

// MARK: - Public report metadata

enum ReportType: String, Codable, CaseIterable, Sendable {
    case lost, found

    var displayName: String { self == .lost ? "Lost" : "Found" }
    var icon: String { self == .lost ? "magnifyingglass" : "hand.raised.fill" }
}

enum ItemCategory: String, Codable, CaseIterable, Identifiable, Sendable {
    case electronics = "Electronics", bags = "Bags", clothing = "Clothing", keys = "Keys"
    case idCards = "ID / Cards", books = "Books", accessories = "Accessories", other = "Other"

    var id: String { rawValue }
    var icon: String {
        switch self {
        case .electronics: "bolt.fill"
        case .bags: "bag.fill"
        case .clothing: "tshirt.fill"
        case .keys: "key.fill"
        case .idCards: "creditcard.fill"
        case .books: "book.fill"
        case .accessories: "watchface.applewatch.case"
        case .other: "square.grid.2x2.fill"
        }
    }
}

enum ReportState: String, Codable, CaseIterable, Sendable {
    case draft, active, underReview, hidden, resolved, rejected
    var displayName: String {
        switch self {
        case .draft: "Draft"
        case .active: "Active"
        case .underReview: "Under Review"
        case .hidden: "Hidden"
        case .resolved: "Resolved"
        case .rejected: "Rejected"
        }
    }
}

/// Retained for compatibility with the existing badge component.
enum ItemStatus: String, Codable, Sendable {
    case active, matched, returned, closed
    var displayName: String { rawValue.capitalized }
}

@Model
final class ItemReport {
    @Attribute(.unique) var id: UUID
    var ownerID: String
    var reportType: String
    var name: String
    var category: String
    var itemDescription: String
    var publicLocationName: String
    var privateLatitude: Double?
    var privateLongitude: Double?
    var publicLatitude: Double?
    var publicLongitude: Double?
    var campusPlaceID: String?
    var occurredAt: Date
    var createdAt: Date
    var updatedAt: Date
    var resolvedAt: Date?
    var photoData: Data?
    var thumbnailData: Data?
    var colorHint: String
    var detectedText: String
    var state: String
    var isDemo: Bool

    var reportTypeEnum: ReportType { ReportType(rawValue: reportType) ?? .lost }
    var categoryEnum: ItemCategory { ItemCategory(rawValue: category) ?? .other }
    var stateEnum: ReportState { ReportState(rawValue: state) ?? .active }
    var statusEnum: ItemStatus {
        switch stateEnum {
        case .active: .active
        case .underReview: .matched
        case .resolved: .returned
        case .draft, .hidden, .rejected: .closed
        }
    }
    var coordinate: CLLocationCoordinate2D? {
        guard let privateLatitude, let privateLongitude else { return nil }
        return CLLocationCoordinate2D(latitude: privateLatitude, longitude: privateLongitude)
    }
    var publicCoordinate: CLLocationCoordinate2D? {
        guard let publicLatitude, let publicLongitude else { return nil }
        return CLLocationCoordinate2D(latitude: publicLatitude, longitude: publicLongitude)
    }
    var approximateLocation: String { publicLocationName.isEmpty ? "Location withheld" : publicLocationName }
    var isActive: Bool { stateEnum == .active || stateEnum == .underReview }

    init(
        id: UUID = UUID(), ownerID: String, reportType: ReportType, name: String,
        category: ItemCategory, itemDescription: String, publicLocationName: String,
        privateCoordinate: CLLocationCoordinate2D? = nil,
        publicCoordinate: CLLocationCoordinate2D? = nil,
        campusPlaceID: String? = nil, occurredAt: Date = .now, createdAt: Date = .now,
        photoData: Data? = nil, thumbnailData: Data? = nil, colorHint: String = "",
        detectedText: String = "", state: ReportState = .active, isDemo: Bool = false
    ) {
        self.id = id; self.ownerID = ownerID; self.reportType = reportType.rawValue; self.name = name; self.category = category.rawValue
        self.itemDescription = itemDescription; self.publicLocationName = publicLocationName
        self.privateLatitude = privateCoordinate?.latitude; self.privateLongitude = privateCoordinate?.longitude
        self.publicLatitude = publicCoordinate?.latitude; self.publicLongitude = publicCoordinate?.longitude
        self.campusPlaceID = campusPlaceID; self.occurredAt = occurredAt; self.createdAt = createdAt; self.updatedAt = createdAt
        self.photoData = photoData; self.thumbnailData = thumbnailData; self.colorHint = colorHint; self.detectedText = detectedText
        self.state = state.rawValue; self.isDemo = isDemo
    }
}

// MARK: - Persisted lifecycle records

enum MatchStatus: String, Codable, CaseIterable, Sendable { case potential, likely, strong, claimSubmitted, verified, rejected, resolved }

struct MatchFactor: Codable, Identifiable, Hashable, Sendable {
    var id: UUID = UUID()
    var icon: String
    var text: String
    var weight: Double
}

@Model
final class MatchRecord {
    @Attribute(.unique) var id: UUID
    var lostReportID: UUID
    var foundReportID: UUID
    var score: Double
    var createdAt: Date
    var updatedAt: Date
    var status: String
    var factorsData: Data
    var statusEnum: MatchStatus { MatchStatus(rawValue: status) ?? .potential }
    var confidencePercent: Int { Int((score * 100).rounded()) }
    var factors: [MatchFactor] { (try? JSONDecoder().decode([MatchFactor].self, from: factorsData)) ?? [] }

    init(id: UUID = UUID(), lostReportID: UUID, foundReportID: UUID, score: Double,
         status: MatchStatus, factors: [MatchFactor], createdAt: Date = .now) {
        self.id = id; self.lostReportID = lostReportID; self.foundReportID = foundReportID; self.score = score
        self.createdAt = createdAt; self.updatedAt = createdAt; self.status = status.rawValue
        self.factorsData = (try? JSONEncoder().encode(factors)) ?? Data()
    }
}

enum ClaimStatus: String, Codable, CaseIterable, Sendable { case pending, verified, rejected, needsReview, cancelled }

@Model
final class ClaimRequest {
    @Attribute(.unique) var id: UUID
    var reportID: UUID
    var matchID: UUID?
    var claimantID: String
    var createdAt: Date
    var reviewedAt: Date?
    var status: String
    var verificationScore: Double
    var failedAttempts: Int
    var statusEnum: ClaimStatus { ClaimStatus(rawValue: status) ?? .pending }
    init(id: UUID = UUID(), reportID: UUID, matchID: UUID? = nil, claimantID: String,
         status: ClaimStatus = .pending, verificationScore: Double = 0, createdAt: Date = .now) {
        self.id = id; self.reportID = reportID; self.matchID = matchID; self.claimantID = claimantID
        self.createdAt = createdAt; self.status = status.rawValue; self.verificationScore = verificationScore; self.failedAttempts = 0
    }
}

enum ReturnArrangementStatus: String, Codable, CaseIterable, Sendable { case proposed, confirmed, cancelled, completed, noShow }

@Model
final class ReturnArrangement {
    @Attribute(.unique) var id: UUID
    var claimID: UUID
    var locationName: String
    var latitude: Double?
    var longitude: Double?
    var scheduledAt: Date
    var notes: String
    var status: String
    var createdAt: Date
    var updatedAt: Date
    var statusEnum: ReturnArrangementStatus { ReturnArrangementStatus(rawValue: status) ?? .proposed }
    init(id: UUID = UUID(), claimID: UUID, locationName: String, coordinate: CLLocationCoordinate2D? = nil,
         scheduledAt: Date, notes: String = "", status: ReturnArrangementStatus = .proposed, createdAt: Date = .now) {
        self.id = id; self.claimID = claimID; self.locationName = locationName; self.latitude = coordinate?.latitude; self.longitude = coordinate?.longitude
        self.scheduledAt = scheduledAt; self.notes = notes; self.status = status.rawValue; self.createdAt = createdAt; self.updatedAt = createdAt
    }
}

@Model
final class CoordinationMessage {
    @Attribute(.unique) var id: UUID
    var claimID: UUID
    var senderID: String
    var body: String
    var createdAt: Date
    init(id: UUID = UUID(), claimID: UUID, senderID: String, body: String, createdAt: Date = .now) {
        self.id = id; self.claimID = claimID; self.senderID = senderID; self.body = body; self.createdAt = createdAt
    }
}

enum ActivityEventType: String, Codable, CaseIterable, Sendable {
    case potentialMatch, strongMatch, claimSubmitted, verificationRequired, claimVerified, claimRejected
    case pickupScheduled, pickupReminder, returnCompleted, reportResolved
}

@Model
final class ActivityEvent {
    @Attribute(.unique) var id: UUID
    var recipientID: String
    var type: String
    var title: String
    var message: String
    var createdAt: Date
    var isRead: Bool
    var relatedReportID: UUID?
    var relatedClaimID: UUID?
    var typeEnum: ActivityEventType { ActivityEventType(rawValue: type) ?? .potentialMatch }
    init(id: UUID = UUID(), recipientID: String, type: ActivityEventType, title: String, message: String,
         relatedReportID: UUID? = nil, relatedClaimID: UUID? = nil, createdAt: Date = .now) {
        self.id = id; self.recipientID = recipientID; self.type = type.rawValue; self.title = title; self.message = message
        self.createdAt = createdAt; self.isRead = false; self.relatedReportID = relatedReportID; self.relatedClaimID = relatedClaimID
    }
}

enum ModerationReason: String, Codable, CaseIterable, Sendable { case fakeReport, falseClaim, spam, harassment, suspiciousBehavior, incorrectInformation }
enum ModerationStatus: String, Codable, CaseIterable, Sendable { case pending, reviewed, resolved, dismissed }

@Model
final class ModerationReport {
    @Attribute(.unique) var id: UUID
    var targetID: UUID
    var reason: String
    var details: String
    var createdAt: Date
    var status: String
    init(id: UUID = UUID(), targetID: UUID, reason: ModerationReason, details: String = "", createdAt: Date = .now) {
        self.id = id; self.targetID = targetID; self.reason = reason.rawValue; self.details = details; self.createdAt = createdAt; self.status = ModerationStatus.pending.rawValue
    }
}

// MARK: - View adapters

enum ConfidenceTier { case high, medium, low
    var label: String { self == .high ? "High Confidence" : self == .medium ? "Possible Match" : "Low Confidence" }
}

struct MatchReason: Identifiable {
    let id = UUID()
    let icon: String
    let text: String
}

/// A transient presentation wrapper around a persisted MatchRecord and its two reports.
struct ItemMatch: Identifiable {
    let id: UUID
    let lostReport: ItemReport
    let foundReport: ItemReport
    let confidence: Double
    let reasons: [MatchReason]
    init(record: MatchRecord, lostReport: ItemReport, foundReport: ItemReport) {
        id = record.id; self.lostReport = lostReport; self.foundReport = foundReport; confidence = record.score
        reasons = record.factors.map { MatchReason(icon: $0.icon, text: $0.text) }
    }
    var confidencePercent: Int { Int((confidence * 100).rounded()) }
    var confidenceTier: ConfidenceTier { confidence >= 0.75 ? .high : confidence >= 0.50 ? .medium : .low }
}
