import Foundation
import SwiftData
import CoreLocation

// MARK: - Enums

enum ReportType: String, Codable, CaseIterable {
    case lost = "lost"
    case found = "found"

    var displayName: String {
        switch self {
        case .lost: return "Lost"
        case .found: return "Found"
        }
    }

    var icon: String {
        switch self {
        case .lost: return "magnifyingglass"
        case .found: return "hand.raised.fill"
        }
    }
}

enum ItemCategory: String, Codable, CaseIterable, Identifiable {
    case electronics = "Electronics"
    case bags = "Bags"
    case clothing = "Clothing"
    case keys = "Keys"
    case idCards = "ID / Cards"
    case books = "Books"
    case accessories = "Accessories"
    case other = "Other"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .electronics: return "bolt.fill"
        case .bags: return "bag.fill"
        case .clothing: return "tshirt.fill"
        case .keys: return "key.fill"
        case .idCards: return "creditcard.fill"
        case .books: return "book.fill"
        case .accessories: return "watchface.applewatch.case"
        case .other: return "square.grid.2x2.fill"
        }
    }
}

enum ItemStatus: String, Codable {
    case active = "active"
    case matched = "matched"
    case returned = "returned"
    case closed = "closed"

    var displayName: String {
        switch self {
        case .active: return "Active"
        case .matched: return "Matched"
        case .returned: return "Returned"
        case .closed: return "Closed"
        }
    }
}

// MARK: - ItemReport (SwiftData Model)

@Model
final class ItemReport {
    var id: UUID
    var reportType: String          // ReportType.rawValue
    var name: String
    var category: String            // ItemCategory.rawValue
    var itemDescription: String
    var locationName: String
    var latitude: Double?
    var longitude: Double?
    var date: Date
    var dateReported: Date
    var photoData: Data?
    var privateDetails: String      // NOT shown publicly — for ownership verification
    var status: String              // ItemStatus.rawValue
    var colorHint: String           // e.g. "black", "blue"

    // Computed helpers (not persisted)
    var reportTypeEnum: ReportType {
        ReportType(rawValue: reportType) ?? .lost
    }

    var categoryEnum: ItemCategory {
        ItemCategory(rawValue: category) ?? .other
    }

    var statusEnum: ItemStatus {
        ItemStatus(rawValue: status) ?? .active
    }

    var coordinate: CLLocationCoordinate2D? {
        guard let lat = latitude, let lon = longitude else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }

    var approximateLocation: String {
        locationName.isEmpty ? "Unknown location" : locationName
    }

    init(
        id: UUID = UUID(),
        reportType: ReportType,
        name: String,
        category: ItemCategory,
        itemDescription: String,
        locationName: String,
        latitude: Double? = nil,
        longitude: Double? = nil,
        date: Date = Date(),
        dateReported: Date = Date(),
        photoData: Data? = nil,
        privateDetails: String = "",
        status: ItemStatus = .active,
        colorHint: String = ""
    ) {
        self.id = id
        self.reportType = reportType.rawValue
        self.name = name
        self.category = category.rawValue
        self.itemDescription = itemDescription
        self.locationName = locationName
        self.latitude = latitude
        self.longitude = longitude
        self.date = date
        self.dateReported = dateReported
        self.photoData = photoData
        self.privateDetails = privateDetails
        self.status = status.rawValue
        self.colorHint = colorHint
    }
}

// MARK: - Match (In-Memory)

struct ItemMatch: Identifiable {
    let id: UUID
    let lostReport: MockItemReport  // Using mock type for demo
    let foundReport: MockItemReport
    let confidence: Double          // 0.0 – 1.0
    let reasons: [MatchReason]

    var confidencePercent: Int { Int(confidence * 100) }

    var confidenceTier: ConfidenceTier {
        switch confidence {
        case 0.75...: return .high
        case 0.50..<0.75: return .medium
        default: return .low
        }
    }
}

enum ConfidenceTier {
    case high, medium, low

    var label: String {
        switch self {
        case .high: return "High Confidence"
        case .medium: return "Possible Match"
        case .low: return "Low Confidence"
        }
    }
}

struct MatchReason: Identifiable {
    let id = UUID()
    let icon: String
    let text: String
}

// MARK: - OwnershipRequest (In-Memory)

enum OwnershipRequestStatus {
    case pending, accepted, rejected, verified
}

struct OwnershipRequest: Identifiable {
    let id = UUID()
    let matchID: UUID
    var status: OwnershipRequestStatus
    let challengeQuestion: String   // Derived from privateDetails
    let dateSubmitted: Date
}

// MARK: - Mock Item (for demo / sample data layer)
// This mirrors ItemReport but is a plain struct for easy mock usage.

struct MockItemReport: Identifiable {
    var id: UUID = UUID()
    var reportType: ReportType
    var name: String
    var category: ItemCategory
    var itemDescription: String
    var locationName: String
    var latitude: Double?
    var longitude: Double?
    var date: Date
    var dateReported: Date = Date()
    var imageName: String?          // SF Symbol or system image name for mocks
    var photoData: Data? = nil
    var privateDetails: String = ""
    var status: ItemStatus = .active
    var colorHint: String = ""

    var coordinate: CLLocationCoordinate2D? {
        guard let lat = latitude, let lon = longitude else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }

    var approximateLocation: String {
        locationName.isEmpty ? "Unknown location" : locationName
    }
}
