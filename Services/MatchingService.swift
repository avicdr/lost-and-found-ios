import Foundation
import CoreLocation

struct MatchingConfiguration: Sendable {
    let categoryWeight = 0.25
    let nameWeight = 0.20
    let descriptionWeight = 0.20
    let locationWeight = 0.15
    let colorWeight = 0.10
    let timeWeight = 0.10
    let minimumScore = 0.35
    let fullLocationDistance: CLLocationDistance = 100
    let maximumLocationDistance: CLLocationDistance = 2_000
    let maximumTimeDifference: TimeInterval = 7 * 24 * 60 * 60
}

struct ScoredMatch: Identifiable, Sendable {
    var id: UUID { UUID() }
    let lostReportID: UUID
    let foundReportID: UUID
    let score: Double
    let status: MatchStatus
    let factors: [MatchFactor]
}

protocol MatchingServiceProtocol {
    func score(lost: ItemReport, found: ItemReport) -> ScoredMatch?
}

final class MatchingService: MatchingServiceProtocol {
    private let configuration: MatchingConfiguration
    init(configuration: MatchingConfiguration = .init()) { self.configuration = configuration }

    func score(lost: ItemReport, found: ItemReport) -> ScoredMatch? {
        guard lost.reportTypeEnum == .lost, found.reportTypeEnum == .found, lost.isActive, found.isActive else { return nil }
        var score = 0.0
        var factors = [MatchFactor]()
        if lost.categoryEnum == found.categoryEnum {
            score += configuration.categoryWeight
            factors.append(.init(icon: "checkmark.circle.fill", text: "Same category: \(lost.categoryEnum.rawValue)", weight: configuration.categoryWeight))
        }
        let nameSimilarity = similarity(lost.name, found.name)
        if nameSimilarity > 0 {
            score += nameSimilarity * configuration.nameWeight
            if nameSimilarity >= 0.20 { factors.append(.init(icon: "checkmark.circle.fill", text: "Similar item name", weight: nameSimilarity * configuration.nameWeight)) }
        }
        let descriptionSimilarity = similarity(lost.itemDescription, found.itemDescription)
        if descriptionSimilarity > 0 {
            score += descriptionSimilarity * configuration.descriptionWeight
            if descriptionSimilarity >= 0.12 { factors.append(.init(icon: "checkmark.circle.fill", text: "Similar description", weight: descriptionSimilarity * configuration.descriptionWeight)) }
        }
        let lostColor = lost.colorHint.isEmpty ? (lost.name + " " + lost.itemDescription).normalizedColorKeyword : lost.colorHint.lowercased()
        let foundColor = found.colorHint.isEmpty ? (found.name + " " + found.itemDescription).normalizedColorKeyword : found.colorHint.lowercased()
        if let lostColor, let foundColor, lostColor == foundColor {
            score += configuration.colorWeight
            factors.append(.init(icon: "checkmark.circle.fill", text: "Same color: \(lostColor.capitalized)", weight: configuration.colorWeight))
        }
        if let lostCoordinate = lost.coordinate, let foundCoordinate = found.coordinate {
            let distance = lostCoordinate.distance(to: foundCoordinate)
            let locationScore = max(0, 1 - (distance - configuration.fullLocationDistance) / (configuration.maximumLocationDistance - configuration.fullLocationDistance))
            if distance <= configuration.maximumLocationDistance {
                score += locationScore * configuration.locationWeight
                factors.append(.init(icon: distance <= configuration.fullLocationDistance ? "checkmark.circle.fill" : "location.circle", text: "Reported \(distance.metersToKmString) apart", weight: locationScore * configuration.locationWeight))
            }
        }
        let difference = abs(lost.occurredAt.timeIntervalSince(found.occurredAt))
        if difference <= configuration.maximumTimeDifference {
            let timeScore = 1 - difference / configuration.maximumTimeDifference
            score += timeScore * configuration.timeWeight
            let hours = max(1, Int(difference / 3600))
            factors.append(.init(icon: "clock", text: "Reported within \(hours) hour\(hours == 1 ? "" : "s")", weight: timeScore * configuration.timeWeight))
        }
        guard score >= configuration.minimumScore else { return nil }
        let status: MatchStatus = score >= 0.75 ? .strong : score >= 0.55 ? .likely : .potential
        return ScoredMatch(lostReportID: lost.id, foundReportID: found.id, score: min(score, 0.99), status: status, factors: factors)
    }

    private func similarity(_ lhs: String, _ rhs: String) -> Double {
        let lhsWords = lhs.keywords(); let rhsWords = rhs.keywords()
        guard !lhsWords.isEmpty, !rhsWords.isEmpty else { return 0 }
        return Double(lhsWords.intersection(rhsWords).count) / Double(lhsWords.union(rhsWords).count)
    }
}
