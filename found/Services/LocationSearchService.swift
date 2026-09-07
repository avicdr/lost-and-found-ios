import MapKit

@Observable
final class LocationSearchService: NSObject, MKLocalSearchCompleterDelegate {
    var query = "" { didSet { completer.queryFragment = query } }
    var results: [MKLocalSearchCompletion] = []
    private let completer = MKLocalSearchCompleter()
    override init() { super.init(); completer.delegate = self; completer.resultTypes = [.address, .pointOfInterest] }
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) { results = completer.results }
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) { results = [] }
    func resolve(_ completion: MKLocalSearchCompletion) async throws -> MKMapItem? {
        let response = try await MKLocalSearch(request: .init(completion: completion)).start()
        return response.mapItems.first
    }
}
