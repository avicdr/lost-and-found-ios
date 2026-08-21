import Foundation
import CoreLocation

// MARK: - Date Extensions

extension Date {
    var relativeDescription: String {
        let now = Date()
        let diff = now.timeIntervalSince(self)

        if diff < 60 { return "Just now" }
        if diff < 3600 { return "\(Int(diff / 60))m ago" }
        if diff < 86400 { return "\(Int(diff / 3600))h ago" }
        if diff < 604800 { return "\(Int(diff / 86400))d ago" }

        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: self)
    }

    var shortDateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }

    var dayString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter.string(from: self)
    }
}

// MARK: - CLLocationCoordinate2D Extensions

extension CLLocationCoordinate2D {
    func distance(to other: CLLocationCoordinate2D) -> Double {
        let loc1 = CLLocation(latitude: latitude, longitude: longitude)
        let loc2 = CLLocation(latitude: other.latitude, longitude: other.longitude)
        return loc1.distance(from: loc2)
    }

    var distanceDisplayString: String? { nil } // computed from context
}

// MARK: - Double Extensions

extension Double {
    var metersToKmString: String {
        if self < 1000 { return "\(Int(self))m" }
        return String(format: "%.1fkm", self / 1000)
    }
}

// MARK: - String Extensions

extension String {
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func keywords() -> Set<String> {
        let stopWords: Set<String> = ["a", "an", "the", "and", "or", "but", "in", "on", "at", "to", "for", "of", "with", "my", "it", "its", "this", "that", "i", "me", "was", "is", "are", "have", "had", "has", "be", "been"]
        let words = lowercased()
            .components(separatedBy: .init(charactersIn: " ,.!?-_/\\:;\"'"))
            .filter { $0.count > 2 && !stopWords.contains($0) }
        return Set(words)
    }
}

// MARK: - Color keyword normalization

extension String {
    /// Attempts to normalize a color keyword from text
    var normalizedColorKeyword: String? {
        let colorMap: [String: String] = [
            "black": "black",
            "white": "white",
            "gray": "gray", "grey": "gray",
            "silver": "silver",
            "red": "red",
            "blue": "blue", "navy": "blue", "dark blue": "blue",
            "green": "green", "olive": "green",
            "yellow": "yellow",
            "orange": "orange",
            "purple": "purple",
            "pink": "pink",
            "brown": "brown", "tan": "brown",
            "gold": "gold", "golden": "gold",
            "beige": "beige",
            "clear": "clear", "transparent": "clear"
        ]

        let lower = lowercased()
        for (key, value) in colorMap {
            if lower.contains(key) { return value }
        }
        return nil
    }
}
