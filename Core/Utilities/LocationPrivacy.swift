import CoreLocation

enum LocationPrivacy {
    /// Rounds to roughly 110m. Matching retains the original coordinate locally.
    static func approximate(_ coordinate: CLLocationCoordinate2D?, precision: Double = 0.001) -> CLLocationCoordinate2D? {
        guard let coordinate else { return nil }
        return CLLocationCoordinate2D(latitude: (coordinate.latitude / precision).rounded() * precision,
                                      longitude: (coordinate.longitude / precision).rounded() * precision)
    }
}
