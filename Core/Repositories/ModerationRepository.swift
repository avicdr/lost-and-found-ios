import Foundation
import SwiftData

@MainActor
final class ModerationRepository {
    private let context: ModelContext
    init(context: ModelContext) { self.context = context }
    func submit(targetID: UUID, reason: ModerationReason, details: String = "") throws {
        context.insert(ModerationReport(targetID: targetID, reason: reason, details: details.trimmed))
        try context.save()
    }
}
