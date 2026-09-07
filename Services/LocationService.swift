import CoreLocation
import Combine

// MARK: - LocationService

@Observable
final class LocationService: NSObject, CLLocationManagerDelegate {

    // MARK: Published State
    var authorizationStatus: CLAuthorizationStatus = .notDetermined
    var currentLocation: CLLocation?
    var currentPlacemark: CLPlacemark?
    var locationErrorMessage: String?
    var isLocating: Bool = false

    var hasPermission: Bool {
        authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways
    }

    var locationDenied: Bool {
        authorizationStatus == .denied || authorizationStatus == .restricted
    }

    // MARK: Private
    private let manager = CLLocationManager()
    private let geocoder = CLGeocoder()
    private var locationWaiters: [CheckedContinuation<CLLocation?, Never>] = []

    // MARK: Init
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters // approximate
        authorizationStatus = manager.authorizationStatus
    }

    // MARK: - Public API

    /// Request permission with explanation context
    func requestPermission() {
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            locationErrorMessage = "Location access is turned off. You can still enter a location manually."
        default:
            break
        }
    }

    /// Get current location (one-shot)
    func fetchCurrentLocation() {
        guard hasPermission else {
            requestPermission()
            return
        }
        isLocating = true
        locationErrorMessage = nil
        manager.requestLocation()
    }

    /// A one-shot async API for reporting and nearby discovery.
    func currentLocationOnce() async -> CLLocation? {
        guard hasPermission else {
            requestPermission()
            return nil
        }
        return await withCheckedContinuation { continuation in
            locationWaiters.append(continuation)
            fetchCurrentLocation()
        }
    }

    /// Reverse geocode coordinates to a human-readable name
    func reverseGeocode(coordinate: CLLocationCoordinate2D) async -> String? {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            guard let p = placemarks.first else { return nil }
            let parts = [p.name, p.subLocality, p.locality].compactMap { $0 }
            return parts.first ?? p.locality
        } catch {
            return nil
        }
    }

    // MARK: - CLLocationManagerDelegate

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        if hasPermission && isLocating {
            manager.requestLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        isLocating = false
        currentLocation = locations.last

        if let loc = currentLocation {
            let waiters = locationWaiters
            locationWaiters.removeAll()
            waiters.forEach { $0.resume(returning: loc) }
            Task {
                let placemarks = try? await geocoder.reverseGeocodeLocation(loc)
                currentPlacemark = placemarks?.first
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        isLocating = false
        locationErrorMessage = "Couldn't get your location. Please enter it manually."
        let waiters = locationWaiters
        locationWaiters.removeAll()
        waiters.forEach { $0.resume(returning: nil) }
    }
}
