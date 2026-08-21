import Foundation
import CoreLocation

// MARK: - Mock Data Layer
// Clearly separated from production data. This is demo/preview data only.

enum MockData {

    // MARK: Sample Campus Coordinates (generic university campus)
    static let campusCenter = CLLocationCoordinate2D(latitude: 37.8719, longitude: -122.2585) // UC Berkeley-ish

    // MARK: Lost Items
    static let lostItems: [MockItemReport] = [
        MockItemReport(
            reportType: .lost,
            name: "Black AirPods Pro Case",
            category: .electronics,
            itemDescription: "Small black charging case for AirPods Pro. Has a small scratch on the lid. Case only, no AirPods inside.",
            locationName: "Main Library, 2nd Floor",
            latitude: 37.8726,
            longitude: -122.2596,
            date: Calendar.current.date(byAdding: .hour, value: -3, to: Date())!,
            imageName: "airpodspro",
            privateDetails: "There's a tiny Pusheen sticker on the inside lid of the case.",
            status: .active,
            colorHint: "black"
        ),
        MockItemReport(
            reportType: .lost,
            name: "Blue Nike Backpack",
            category: .bags,
            itemDescription: "Medium-sized navy blue Nike backpack. Has a broken zipper on the front pocket. Contains notebooks.",
            locationName: "Student Union, Cafeteria",
            latitude: 37.8701,
            longitude: -122.2601,
            date: Calendar.current.date(byAdding: .hour, value: -8, to: Date())!,
            imageName: "bag",
            privateDetails: "My student ID is inside along with a red Moleskine notebook.",
            status: .active,
            colorHint: "blue"
        ),
        MockItemReport(
            reportType: .lost,
            name: "Silver MacBook Charger",
            category: .electronics,
            itemDescription: "Apple 67W USB-C power adapter with MagSafe cable. Has white electrical tape near the USB-C end.",
            locationName: "Engineering Building, Room 204",
            latitude: 37.8745,
            longitude: -122.2570,
            date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!,
            imageName: "cable.connector",
            privateDetails: "My initials 'AS' are scratched into the back of the brick.",
            status: .matched,
            colorHint: "silver"
        ),
        MockItemReport(
            reportType: .lost,
            name: "Student ID Card",
            category: .idCards,
            itemDescription: "University student ID card. Has my photo and a blue lanyard attached.",
            locationName: "Campus Bus Stop, North Gate",
            latitude: 37.8750,
            longitude: -122.2610,
            date: Calendar.current.date(byAdding: .hour, value: -5, to: Date())!,
            imageName: "creditcard",
            privateDetails: "Student ID number is 10491837. The card has a small coffee stain on the back.",
            status: .active,
            colorHint: "blue"
        ),
        MockItemReport(
            reportType: .lost,
            name: "House Keys",
            category: .keys,
            itemDescription: "Set of 3 keys on a small carabiner. Has an orange keychain fob from IKEA.",
            locationName: "Gym Locker Room",
            latitude: 37.8680,
            longitude: -122.2590,
            date: Calendar.current.date(byAdding: .hour, value: -2, to: Date())!,
            imageName: "key",
            privateDetails: "One key has a yellow painted tip. The carabiner says 'Petzl'.",
            status: .active,
            colorHint: "orange"
        )
    ]

    // MARK: Found Items
    static let foundItems: [MockItemReport] = [
        MockItemReport(
            reportType: .found,
            name: "Black Wireless Earbuds Case",
            category: .electronics,
            itemDescription: "Found a small black wireless earbuds charging case near the reading tables on the 2nd floor of the library. No earbuds inside.",
            locationName: "Main Library",
            latitude: 37.8726,
            longitude: -122.2596,
            date: Calendar.current.date(byAdding: .hour, value: -2, to: Date())!,
            imageName: "airpodspro",
            privateDetails: "There's a small sticker on the inside of the lid.",
            status: .active,
            colorHint: "black"
        ),
        MockItemReport(
            reportType: .found,
            name: "Navy Backpack",
            category: .bags,
            itemDescription: "Found a large dark blue backpack near the cashier. Handed it to the front desk. Appears to have some school supplies inside.",
            locationName: "Student Union",
            latitude: 37.8701,
            longitude: -122.2603,
            date: Calendar.current.date(byAdding: .hour, value: -6, to: Date())!,
            imageName: "bag",
            status: .active,
            colorHint: "blue"
        ),
        MockItemReport(
            reportType: .found,
            name: "Apple Laptop Charger",
            category: .electronics,
            itemDescription: "White Apple USB-C charger left on a desk in room 204. Has some tape on it.",
            locationName: "Engineering Building",
            latitude: 37.8745,
            longitude: -122.2570,
            date: Calendar.current.date(byAdding: .hour, value: -20, to: Date())!,
            imageName: "cable.connector",
            status: .matched,
            colorHint: "white"
        ),
        MockItemReport(
            reportType: .found,
            name: "Black Water Bottle",
            category: .accessories,
            itemDescription: "Matte black Hydro Flask 32oz water bottle. Found next to a bench near the fountain.",
            locationName: "Campus Quad",
            latitude: 37.8710,
            longitude: -122.2580,
            date: Calendar.current.date(byAdding: .hour, value: -4, to: Date())!,
            imageName: "waterbottle",
            status: .active,
            colorHint: "black"
        ),
        MockItemReport(
            reportType: .found,
            name: "Green Hoodie",
            category: .clothing,
            itemDescription: "Large green Champion hoodie. Left on a seat in the auditorium after the lecture. Has 'UCB' printed on the front.",
            locationName: "Wheeler Hall Auditorium",
            latitude: 37.8730,
            longitude: -122.2592,
            date: Calendar.current.date(byAdding: .day, value: -2, to: Date())!,
            imageName: "tshirt",
            status: .active,
            colorHint: "green"
        ),
        MockItemReport(
            reportType: .found,
            name: "Mathematics Notebook",
            category: .books,
            itemDescription: "Blue Moleskine notebook filled with calculus notes. Name on the inside front cover is partially visible.",
            locationName: "Evans Hall, Stairwell",
            latitude: 37.8738,
            longitude: -122.2560,
            date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!,
            imageName: "book",
            status: .active,
            colorHint: "blue"
        )
    ]

    // MARK: All Items
    static var allItems: [MockItemReport] {
        (lostItems + foundItems).sorted { $0.dateReported > $1.dateReported }
    }

    // MARK: Pre-computed Matches
    static let sampleMatches: [ItemMatch] = {
        guard let lost = lostItems.first, let found = foundItems.first else { return [] }
        let airpodsMatch = ItemMatch(
            id: UUID(),
            lostReport: lostItems[0],
            foundReport: foundItems[0],
            confidence: 0.92,
            reasons: [
                MatchReason(icon: "checkmark.circle.fill", text: "Same category: Electronics"),
                MatchReason(icon: "checkmark.circle.fill", text: "Both mention a black charging case"),
                MatchReason(icon: "checkmark.circle.fill", text: "Reported within 50 meters of each other"),
                MatchReason(icon: "checkmark.circle.fill", text: "Reported within 1 hour")
            ]
        )
        let chargerMatch = ItemMatch(
            id: UUID(),
            lostReport: lostItems[2],
            foundReport: foundItems[2],
            confidence: 0.85,
            reasons: [
                MatchReason(icon: "checkmark.circle.fill", text: "Same category: Electronics"),
                MatchReason(icon: "checkmark.circle.fill", text: "Both mention an Apple charger with tape"),
                MatchReason(icon: "checkmark.circle.fill", text: "Exact same building (Engineering, Room 204)"),
                MatchReason(icon: "checkmark.circle.fill", text: "Reported within 4 hours")
            ]
        )
        let bagMatch = ItemMatch(
            id: UUID(),
            lostReport: lostItems[1],
            foundReport: foundItems[1],
            confidence: 0.73,
            reasons: [
                MatchReason(icon: "checkmark.circle.fill", text: "Same category: Bags"),
                MatchReason(icon: "checkmark.circle.fill", text: "Both describe a dark blue/navy bag"),
                MatchReason(icon: "checkmark.circle.fill", text: "Same location: Student Union"),
                MatchReason(icon: "circle", text: "Time gap: 2 hours apart")
            ]
        )
        return [airpodsMatch, chargerMatch, bagMatch]
    }()
}
