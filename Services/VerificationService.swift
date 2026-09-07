import Foundation

enum VerificationResult: Sendable {
    case verified(score: Double)
    case rejected(score: Double)
    case needsReview(score: Double)
}

protocol VerificationServiceProtocol {
    func verify(answer: String, payload: PrivateVerificationPayload?) -> VerificationResult
}

/// Deterministic, on-device comparison. No answer is logged or copied to public models.
struct VerificationService: VerificationServiceProtocol {
    func verify(answer: String, payload: PrivateVerificationPayload?) -> VerificationResult {
        guard let payload else { return .needsReview(score: 0) }
        let submitted = normalized(answer)
        guard !submitted.isEmpty else { return .rejected(score: 0) }
        let candidates = payload.acceptedAnswers + [payload.identifyingDetails]
        let best = candidates.map { similarity(submitted, normalized($0)) }.max() ?? 0
        if best >= 0.82 { return .verified(score: best) }
        if best >= 0.45 { return .needsReview(score: best) }
        return .rejected(score: best)
    }

    private func normalized(_ text: String) -> String {
        text.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .lowercased().components(separatedBy: CharacterSet.alphanumerics.inverted).joined(separator: " ")
            .split(whereSeparator: \.isWhitespace).joined(separator: " ")
    }

    private func similarity(_ lhs: String, _ rhs: String) -> Double {
        if lhs == rhs { return 1 }
        let left = Set(lhs.split(separator: " ").map(String.init)); let right = Set(rhs.split(separator: " ").map(String.init))
        guard !left.isEmpty, !right.isEmpty else { return 0 }
        let overlap = Double(left.intersection(right).count) / Double(left.union(right).count)
        return max(overlap, lhs.contains(rhs) || rhs.contains(lhs) ? 0.65 : 0)
    }
}
