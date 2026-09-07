import Foundation
import CoreLocation

struct CampusPlace: Identifiable, Sendable {
    enum Category: String, CaseIterable, Sendable { case library, cafeteria, hostel, academicBlock, parking, sportsComplex, auditorium, lab, office }
    let id: String
    let name: String
    let coordinate: CLLocationCoordinate2D
    let category: Category
}

enum CampusPlaces {
    /// Suggestions are centralized here, never embedded in view layout. Coordinates are only defaults;
    /// a user may always search or select a different place on the map.
    static let suggested: [CampusPlace] = [
        .init(id: "library", name: "Library", coordinate: .init(latitude: 37.8726, longitude: -122.2596), category: .library),
        .init(id: "cafeteria", name: "Cafeteria", coordinate: .init(latitude: 37.8701, longitude: -122.2601), category: .cafeteria),
        .init(id: "hostel", name: "Hostel", coordinate: .init(latitude: 37.8692, longitude: -122.2575), category: .hostel),
        .init(id: "academic-block", name: "Academic Block", coordinate: .init(latitude: 37.8745, longitude: -122.2570), category: .academicBlock),
        .init(id: "parking", name: "Campus Parking", coordinate: .init(latitude: 37.8750, longitude: -122.2610), category: .parking),
        .init(id: "sports", name: "Sports Complex", coordinate: .init(latitude: 37.8680, longitude: -122.2590), category: .sportsComplex),
        .init(id: "auditorium", name: "Auditorium", coordinate: .init(latitude: 37.8730, longitude: -122.2592), category: .auditorium),
        .init(id: "lab", name: "Campus Lab", coordinate: .init(latitude: 37.8738, longitude: -122.2560), category: .lab)
    ]
}
