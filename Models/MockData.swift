import Foundation
import CoreLocation

/// Explicit, deterministic data for previews and the optional first-run demo seed.
/// Production screens never read this directly.
enum DemoData {
    struct SeedReport: Identifiable {
        let id: UUID
        let ownerID: String
        let reportType: ReportType
        let name: String
        let category: ItemCategory
        let description: String
        let locationName: String
        let coordinate: CLLocationCoordinate2D
        let occurredAt: Date
        let createdAt: Date
        let colorHint: String
    }

    static let reports: [SeedReport] = [
        SeedReport(id: UUID(uuidString: "D4101F6D-A915-4D49-BE76-0E9D90A1F001")!, ownerID: "demo-finder-1", reportType: .found,
                   name: "Black Wireless Earbuds Case", category: .electronics,
                   description: "Small black charging case found near reading tables. No earbuds inside.", locationName: "Main Library",
                   coordinate: .init(latitude: 37.8726, longitude: -122.2596), occurredAt: .now.addingTimeInterval(-7200), createdAt: .now.addingTimeInterval(-7200), colorHint: "black"),
        SeedReport(id: UUID(uuidString: "D4101F6D-A915-4D49-BE76-0E9D90A1F002")!, ownerID: "demo-owner-1", reportType: .lost,
                   name: "Blue Nike Backpack", category: .bags,
                   description: "Navy blue backpack with a broken front-pocket zipper.", locationName: "Student Union",
                   coordinate: .init(latitude: 37.8701, longitude: -122.2601), occurredAt: .now.addingTimeInterval(-28800), createdAt: .now.addingTimeInterval(-28800), colorHint: "blue"),
        SeedReport(id: UUID(uuidString: "D4101F6D-A915-4D49-BE76-0E9D90A1F003")!, ownerID: "demo-finder-2", reportType: .found,
                   name: "Navy Backpack", category: .bags,
                   description: "Large dark blue backpack found near the cashier with school supplies.", locationName: "Student Union",
                   coordinate: .init(latitude: 37.8701, longitude: -122.2603), occurredAt: .now.addingTimeInterval(-21600), createdAt: .now.addingTimeInterval(-21600), colorHint: "blue"),
        SeedReport(id: UUID(uuidString: "D4101F6D-A915-4D49-BE76-0E9D90A1F004")!, ownerID: "demo-finder-3", reportType: .found,
                   name: "Green Hoodie", category: .clothing,
                   description: "Large green hoodie left in the auditorium.", locationName: "Auditorium",
                   coordinate: .init(latitude: 37.8730, longitude: -122.2592), occurredAt: .now.addingTimeInterval(-172800), createdAt: .now.addingTimeInterval(-172800), colorHint: "green")
    ]
}
