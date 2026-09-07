import SwiftUI
import SwiftData

struct ReturnCoordinationView: View {
    let claim: ClaimRequest
    let report: ItemReport
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var arrangements: [ReturnArrangement]
    @Query private var messages: [CoordinationMessage]
    @State private var locationName = CampusPlaces.suggested.first?.name ?? "Campus Security"
    @State private var scheduledAt = Date.now.addingTimeInterval(3600)
    @State private var notes = ""
    @State private var message = ""
    @State private var errorMessage: String?

    private var arrangement: ReturnArrangement? { arrangements.first { $0.claimID == claim.id } }
    private var thread: [CoordinationMessage] { messages.filter { $0.claimID == claim.id }.sorted { $0.createdAt < $1.createdAt } }
    var body: some View { NavigationStack { ScrollView { VStack(alignment: .leading, spacing: 18) {
        Text("Coordinate a safe campus return").font(AppTheme.Font.title2)
        Text("Use a public pickup point. Do not exchange phone numbers or private contact details here.").font(AppTheme.Font.callout).foregroundStyle(.secondary)
        if let arrangement { arrangementCard(arrangement) } else { schedulingForm }
        messagesSection
    }.padding() }.navigationTitle("Return Arrangement").toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } } }.alert("Couldn’t update arrangement", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) { Button("OK", role: .cancel) {} } message: { Text(errorMessage ?? "") } } }
    private var schedulingForm: some View { VStack(alignment: .leading, spacing: 12) { Text("PICKUP DETAILS").font(AppTheme.Font.overline).foregroundStyle(.secondary); Picker("Location", selection: $locationName) { ForEach(CampusPlaces.suggested) { Text($0.name).tag($0.name) }; Text("Campus Security").tag("Campus Security") }.pickerStyle(.menu); DatePicker("Pickup time", selection: $scheduledAt, in: Date()...); TextField("Optional notes", text: $notes, axis: .vertical).formFieldStyle(); Button("Propose Pickup") { createArrangement() }.buttonStyle(PrimaryButtonStyle()) }.padding(16).background(Color(.secondarySystemGroupedBackground)).clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.lg)) }
    private func arrangementCard(_ arrangement: ReturnArrangement) -> some View { VStack(alignment: .leading, spacing: 10) { Label(arrangement.locationName, systemImage: "mappin.and.ellipse").font(AppTheme.Font.headline); Label(arrangement.scheduledAt.shortDateString, systemImage: "calendar").font(AppTheme.Font.subheadline).foregroundStyle(.secondary); if !arrangement.notes.isEmpty { Text(arrangement.notes).font(AppTheme.Font.callout) }; if arrangement.statusEnum == .proposed { Button("Confirm Pickup") { try? ReturnArrangementRepository(context: modelContext).confirm(arrangement) }.buttonStyle(SecondaryButtonStyle()) } else if arrangement.statusEnum == .confirmed { Button("Mark as handed over") { complete(arrangement) }.buttonStyle(PrimaryButtonStyle()) } else { Label(arrangement.statusEnum.rawValue.capitalized, systemImage: "checkmark.circle.fill").foregroundStyle(AppTheme.Color.highConfidence) } }.padding(16).background(Color(.secondarySystemGroupedBackground)).clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.lg)) }
    private var messagesSection: some View { VStack(alignment: .leading, spacing: 10) { Text("COORDINATION NOTES").font(AppTheme.Font.overline).foregroundStyle(.secondary); if thread.isEmpty { Text("Leave a pickup note such as “I left it at the Library Desk.”").font(AppTheme.Font.caption).foregroundStyle(.secondary) } else { ForEach(thread) { Text($0.body).font(AppTheme.Font.callout).padding(10).background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 10)) } }; HStack { TextField("Write a safe pickup note", text: $message).formFieldStyle(); Button { sendMessage() } label: { Image(systemName: "arrow.up.circle.fill").font(.title2) }.accessibilityLabel("Send coordination note") } } }
    private func createArrangement() { do { let place = CampusPlaces.suggested.first { $0.name == locationName }; _ = try ReturnArrangementRepository(context: modelContext).create(claimID: claim.id, locationName: locationName, coordinate: place?.coordinate, scheduledAt: scheduledAt, notes: notes) } catch { errorMessage = error.localizedDescription } }
    private func sendMessage() { do { try ReturnArrangementRepository(context: modelContext).sendMessage(claimID: claim.id, body: message); message = "" } catch { errorMessage = error.localizedDescription } }
    private func complete(_ arrangement: ReturnArrangement) { do { try ReturnArrangementRepository(context: modelContext).complete(arrangement, report: report); dismiss() } catch { errorMessage = error.localizedDescription } }
}
