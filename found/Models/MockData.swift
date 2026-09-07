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

    /// A varied, populated feed for debug builds and portfolio screenshots.
    /// The values intentionally use relative dates so the feed always feels current.
    static let reports: [SeedReport] = [
        SeedReport(id: UUID(uuidString: "D4101F6D-A915-4D49-BE76-0E9D90A1F001")!, ownerID: "demo-finder-1", reportType: .found,
                   name: "Black Wireless Earbuds Case", category: .electronics,
                   description: "Small black charging case found near reading tables. No earbuds inside.", locationName: "Main Library",
                   coordinate: .init(latitude: 37.8726, longitude: -122.2596), occurredAt: .now.addingTimeInterval(-7200), createdAt: .now.addingTimeInterval(-7200), colorHint: "black"),
        SeedReport(id: UUID(uuidString: "D4101F6D-A915-4D49-BE76-0E9D90A1F002")!, ownerID: "demo-current-user", reportType: .lost,
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
                   coordinate: .init(latitude: 37.8730, longitude: -122.2592), occurredAt: .now.addingTimeInterval(-172800), createdAt: .now.addingTimeInterval(-172800), colorHint: "green"),
        SeedReport(id: UUID(uuidString: "D4101F6D-A915-4D49-BE76-0E9D90A1F005")!, ownerID: "demo-current-user", reportType: .lost,
                   name: "Black Earbuds Charging Case", category: .electronics,
                   description: "Matte black case for wireless earbuds, last seen beside the study booths.", locationName: "Main Library",
                   coordinate: .init(latitude: 37.8725, longitude: -122.2595), occurredAt: .now.addingTimeInterval(-10800), createdAt: .now.addingTimeInterval(-10800), colorHint: "black"),
        SeedReport(id: UUID(uuidString: "D4101F6D-A915-4D49-BE76-0E9D90A1F006")!, ownerID: "demo-current-user", reportType: .lost,
                   name: "Green Zip-up Hoodie", category: .clothing,
                   description: "Forest green hoodie with a small white logo on the left sleeve.", locationName: "Auditorium",
                   coordinate: .init(latitude: 37.8731, longitude: -122.2591), occurredAt: .now.addingTimeInterval(-176400), createdAt: .now.addingTimeInterval(-176400), colorHint: "green"),
        SeedReport(id: UUID(uuidString: "D4101F6D-A915-4D49-BE76-0E9D90A1F007")!, ownerID: "demo-owner-2", reportType: .lost,
                   name: "USB-C Laptop Charger", category: .electronics,
                   description: "White 65W USB-C charging brick and cable, likely left after class.", locationName: "Engineering Building",
                   coordinate: .init(latitude: 37.8714, longitude: -122.2584), occurredAt: .now.addingTimeInterval(-93600), createdAt: .now.addingTimeInterval(-93600), colorHint: "white"),
        SeedReport(id: UUID(uuidString: "D4101F6D-A915-4D49-BE76-0E9D90A1F008")!, ownerID: "demo-finder-4", reportType: .found,
                   name: "White USB-C Laptop Charger", category: .electronics,
                   description: "65W USB-C charging brick with a two-metre cable found below a lecture desk.", locationName: "Engineering Building",
                   coordinate: .init(latitude: 37.8715, longitude: -122.2585), occurredAt: .now.addingTimeInterval(-79200), createdAt: .now.addingTimeInterval(-79200), colorHint: "white"),
        SeedReport(id: UUID(uuidString: "D4101F6D-A915-4D49-BE76-0E9D90A1F009")!, ownerID: "demo-current-user", reportType: .lost,
                   name: "Student ID Card", category: .idCards,
                   description: "Campus ID in a clear holder with a blue lanyard.", locationName: "Science Center",
                   coordinate: .init(latitude: 37.8695, longitude: -122.2578), occurredAt: .now.addingTimeInterval(-187200), createdAt: .now.addingTimeInterval(-187200), colorHint: "blue"),
        SeedReport(id: UUID(uuidString: "D4101F6D-A915-4D49-BE76-0E9D90A1F010")!, ownerID: "demo-finder-5", reportType: .found,
                   name: "Campus Student ID", category: .idCards,
                   description: "Student identification card found outside the science labs in a clear holder.", locationName: "Science Center",
                   coordinate: .init(latitude: 37.8696, longitude: -122.2579), occurredAt: .now.addingTimeInterval(-180000), createdAt: .now.addingTimeInterval(-180000), colorHint: "blue"),
        SeedReport(id: UUID(uuidString: "D4101F6D-A915-4D49-BE76-0E9D90A1F011")!, ownerID: "demo-owner-3", reportType: .lost,
                   name: "Calculus Textbook", category: .books,
                   description: "Paperback calculus textbook with a yellow sticky note on the first chapter.", locationName: "North Quad",
                   coordinate: .init(latitude: 37.8740, longitude: -122.2603), occurredAt: .now.addingTimeInterval(-259200), createdAt: .now.addingTimeInterval(-259200), colorHint: "blue"),
        SeedReport(id: UUID(uuidString: "D4101F6D-A915-4D49-BE76-0E9D90A1F012")!, ownerID: "demo-finder-6", reportType: .found,
                   name: "Calculus I Textbook", category: .books,
                   description: "Blue calculus textbook with a yellow note tucked into the opening pages.", locationName: "North Quad",
                   coordinate: .init(latitude: 37.8741, longitude: -122.2602), occurredAt: .now.addingTimeInterval(-252000), createdAt: .now.addingTimeInterval(-252000), colorHint: "blue"),
        SeedReport(id: UUID(uuidString: "D4101F6D-A915-4D49-BE76-0E9D90A1F013")!, ownerID: "demo-finder-7", reportType: .found,
                   name: "Gold Hoop Earring", category: .accessories,
                   description: "Single small gold hoop earring found near the coffee counter.", locationName: "Campus Café",
                   coordinate: .init(latitude: 37.8708, longitude: -122.2610), occurredAt: .now.addingTimeInterval(-16200), createdAt: .now.addingTimeInterval(-16200), colorHint: "gold"),
        SeedReport(id: UUID(uuidString: "D4101F6D-A915-4D49-BE76-0E9D90A1F014")!, ownerID: "demo-owner-4", reportType: .lost,
                   name: "Insulated Water Bottle", category: .other,
                   description: "Silver insulated water bottle with a mountain sticker on the side.", locationName: "Recreation Center",
                   coordinate: .init(latitude: 37.8688, longitude: -122.2620), occurredAt: .now.addingTimeInterval(-64800), createdAt: .now.addingTimeInterval(-64800), colorHint: "silver")
    ]
}
