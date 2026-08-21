import Foundation
import SwiftData

// MARK: - Legacy Item (kept for SwiftData migration compatibility)
// The primary model is now ItemReport in ItemReport.swift.
// This file is preserved to avoid breaking the initial schema.

@Model
final class Item {
    var timestamp: Date

    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
