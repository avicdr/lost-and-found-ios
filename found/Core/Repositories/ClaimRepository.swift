import Foundation
import SwiftData

@MainActor
final class ClaimRepository {
    private let context: ModelContext
    private let verifier: VerificationServiceProtocol
    init(context: ModelContext, verifier: VerificationServiceProtocol = VerificationService()) { self.context = context; self.verifier = verifier }

    @discardableResult
    func submit(report: ItemReport, match: MatchRecord? = nil, answer: String, claimantID: String = LocalIdentity.userID) throws -> ClaimRequest {
        let claim = ClaimRequest(reportID: report.id, matchID: match?.id, claimantID: claimantID)
        let outcome = verifier.verify(answer: answer, payload: try PrivateVerificationStore.load(for: report.id))
        switch outcome {
        case let .verified(score): claim.status = ClaimStatus.verified.rawValue; claim.verificationScore = score; claim.reviewedAt = .now
        case let .rejected(score): claim.status = ClaimStatus.rejected.rawValue; claim.verificationScore = score; claim.reviewedAt = .now; claim.failedAttempts = 1
        case let .needsReview(score): claim.status = ClaimStatus.needsReview.rawValue; claim.verificationScore = score
        }
        if let match { match.status = (claim.statusEnum == .verified ? MatchStatus.verified : MatchStatus.claimSubmitted).rawValue; match.updatedAt = .now }
        context.insert(claim)
        try context.save()
        let type: ActivityEventType = claim.statusEnum == .verified ? .claimVerified : claim.statusEnum == .rejected ? .claimRejected : .verificationRequired
        _ = try? ActivityRepository(context: context).record(recipientID: report.ownerID, type: type, title: "Ownership claim updated", message: "A claim for \(report.name) was \(claim.statusEnum.rawValue).", reportID: report.id, claimID: claim.id)
        return claim
    }

    func cancel(_ claim: ClaimRequest) throws { claim.status = ClaimStatus.cancelled.rawValue; claim.reviewedAt = .now; try context.save() }
    func claims(for reportID: UUID) throws -> [ClaimRequest] { try context.fetch(FetchDescriptor<ClaimRequest>(predicate: #Predicate { $0.reportID == reportID })) }
}
