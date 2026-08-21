import Foundation
import CoreLocation

// MARK: - MatchingService Protocol
// Clean abstraction — swap in an AI backend later without touching UI.

protocol MatchingServiceProtocol {
    func findMatches(for lostItem: MockItemReport, in foundItems: [MockItemReport]) -> [ItemMatch]
    func topMatches(in allItems: [MockItemReport]) -> [ItemMatch]
}

// MARK: - Local Scoring Implementation

final class MatchingService: MatchingServiceProtocol {

    // MARK: Scoring Weights
    private let categoryWeight: Double = 30
    private let keywordWeight: Double = 30
    private let colorWeight: Double = 20
    private let locationWeight: Double = 10
    private let timeWeight: Double = 10

    /// Minimum confidence to surface a match (0.0–1.0)
    private let minimumConfidence: Double = 0.35

    /// Max distance (meters) to score full location points
    private let maxScoredDistance: Double = 2000

    /// Max time difference (seconds) to score full time points
    private let maxScoredTimeDiff: Double = 7 * 24 * 3600 // 7 days

    // MARK: - Public API

    func findMatches(for lostItem: MockItemReport, in foundItems: [MockItemReport]) -> [ItemMatch] {
        foundItems
            .compactMap { score(lost: lostItem, found: $0) }
            .filter { $0.confidence >= minimumConfidence }
            .sorted { $0.confidence > $1.confidence }
    }

    func topMatches(in allItems: [MockItemReport]) -> [ItemMatch] {
        let lost = allItems.filter { $0.reportType == .lost }
        let found = allItems.filter { $0.reportType == .found }

        var matches: [ItemMatch] = []
        for lostItem in lost {
            let itemMatches = findMatches(for: lostItem, in: found)
            matches.append(contentsOf: itemMatches.prefix(3))
        }
        return matches.sorted { $0.confidence > $1.confidence }
    }

    // MARK: - Private Scoring

    private func score(lost: MockItemReport, found: MockItemReport) -> ItemMatch? {
        var totalScore: Double = 0
        var reasons: [MatchReason] = []

        // 1. Category Match (0–30 pts)
        let categoryScore = scoreCategory(lost: lost, found: found)
        totalScore += categoryScore
        if categoryScore >= categoryWeight {
            reasons.append(MatchReason(icon: "checkmark.circle.fill", text: "Same category: \(lost.category.rawValue)"))
        } else if categoryScore >= categoryWeight * 0.5 {
            reasons.append(MatchReason(icon: "circle", text: "Similar category"))
        }

        // 2. Keyword Overlap (0–30 pts)
        let (keyScore, keyReason) = scoreKeywords(lost: lost, found: found)
        totalScore += keyScore
        if let reason = keyReason { reasons.append(reason) }

        // 3. Color Match (0–20 pts)
        let (colorScore, colorReason) = scoreColor(lost: lost, found: found)
        totalScore += colorScore
        if let reason = colorReason { reasons.append(reason) }

        // 4. Location Proximity (0–10 pts)
        let (locationScore, locationReason) = scoreLocation(lost: lost, found: found)
        totalScore += locationScore
        if let reason = locationReason { reasons.append(reason) }

        // 5. Time Proximity (0–10 pts)
        let (timeScore, timeReason) = scoreTime(lost: lost, found: found)
        totalScore += timeScore
        if let reason = timeReason { reasons.append(reason) }

        let maxScore = categoryWeight + keywordWeight + colorWeight + locationWeight + timeWeight
        let confidence = totalScore / maxScore

        guard confidence >= minimumConfidence else { return nil }

        return ItemMatch(
            id: UUID(),
            lostReport: lost,
            foundReport: found,
            confidence: min(confidence, 0.99),
            reasons: reasons
        )
    }

    private func scoreCategory(lost: MockItemReport, found: MockItemReport) -> Double {
        lost.category == found.category ? categoryWeight : 0
    }

    private func scoreKeywords(lost: MockItemReport, found: MockItemReport) -> (Double, MatchReason?) {
        let lostKeywords = (lost.name + " " + lost.itemDescription).keywords()
        let foundKeywords = (found.name + " " + found.itemDescription).keywords()

        guard !lostKeywords.isEmpty, !foundKeywords.isEmpty else { return (0, nil) }

        let intersection = lostKeywords.intersection(foundKeywords)
        let union = lostKeywords.union(foundKeywords)
        let jaccard = Double(intersection.count) / Double(union.count)
        let score = jaccard * keywordWeight

        var reason: MatchReason? = nil
        if jaccard > 0.25 {
            let sharedWords = intersection.prefix(3).joined(separator: ", ")
            reason = MatchReason(icon: "checkmark.circle.fill", text: "Similar description: \"\(sharedWords)\"")
        } else if jaccard > 0.1 {
            reason = MatchReason(icon: "circle", text: "Some overlapping description")
        }
        return (score, reason)
    }

    private func scoreColor(lost: MockItemReport, found: MockItemReport) -> (Double, MatchReason?) {
        let lostColor = colorKeyword(from: lost)
        let foundColor = colorKeyword(from: found)

        guard let lc = lostColor, let fc = foundColor else { return (0, nil) }
        if lc == fc {
            return (colorWeight, MatchReason(icon: "checkmark.circle.fill", text: "Same color: \(lc.capitalized)"))
        }
        return (0, nil)
    }

    private func colorKeyword(from item: MockItemReport) -> String? {
        if !item.colorHint.isEmpty { return item.colorHint }
        return (item.name + " " + item.itemDescription).normalizedColorKeyword
    }

    private func scoreLocation(lost: MockItemReport, found: MockItemReport) -> (Double, MatchReason?) {
        guard let lc = lost.coordinate, let fc = found.coordinate else {
            // Fuzzy: compare location name words
            let sharedWords = lost.locationName.keywords().intersection(found.locationName.keywords())
            if !sharedWords.isEmpty {
                return (locationWeight * 0.7, MatchReason(icon: "checkmark.circle.fill", text: "Same general area: \(lost.locationName)"))
            }
            return (0, nil)
        }
        let distance = lc.distance(to: fc)
        if distance < 100 {
            return (locationWeight, MatchReason(icon: "checkmark.circle.fill", text: "Reported within \(Int(distance))m of each other"))
        } else if distance < maxScoredDistance {
            let score = (1 - distance / maxScoredDistance) * locationWeight
            return (score, MatchReason(icon: "circle", text: "Reported within \(Int(distance).metersToKmString)"))
        }
        return (0, nil)
    }

    private func scoreTime(lost: MockItemReport, found: MockItemReport) -> (Double, MatchReason?) {
        let timeDiff = abs(lost.date.timeIntervalSince(found.date))
        if timeDiff < 3600 {
            return (timeWeight, MatchReason(icon: "checkmark.circle.fill", text: "Reported within \(Int(timeDiff / 60)) minutes"))
        } else if timeDiff < maxScoredTimeDiff {
            let score = (1 - timeDiff / maxScoredTimeDiff) * timeWeight
            let hours = Int(timeDiff / 3600)
            let days = hours / 24
            let label = days > 0 ? "\(days) day\(days == 1 ? "" : "s")" : "\(hours) hour\(hours == 1 ? "" : "s")"
            return (score, MatchReason(icon: "circle", text: "Reported within \(label)"))
        }
        return (0, nil)
    }
}

extension Int {
    var metersToKmString: String {
        if self < 1000 { return "\(self)m" }
        return String(format: "%.1fkm", Double(self) / 1000)
    }
}
