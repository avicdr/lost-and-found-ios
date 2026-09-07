import SwiftUI
import MapKit

// MARK: - ItemDetailView

struct ItemDetailView: View {
    let item: ItemReport

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var showingClaimFlow = false
    @State private var showingFoundReport = false
    @State private var mapRegion = MKCoordinateRegion()
    @State private var moderationReason: ModerationReason?
    @State private var moderationMessage: String?
    @State private var managementMessage: String?

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 0) {

                        // Hero image / placeholder
                        heroSection

                        // Content
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {

                            // Title + badges
                            headerSection

                            // Details card
                            detailsCard

                            // Description
                            if !item.itemDescription.isEmpty {
                                descriptionSection
                            }

                            // Map
                            if let coord = item.publicCoordinate {
                                mapSection(coord: coord)
                            }

                            // CTA
                            ctaSection
                        }
                        .padding(AppTheme.Spacing.lg)
                    }
                }
                .ignoresSafeArea(edges: .top)
            }
            .navigationTitle(item.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.secondary)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        ForEach(ModerationReason.allCases, id: \.self) { reason in
                            Button("Report: \(reason.rawValue.capitalized)") { submitModeration(reason) }
                        }
                    } label: { Image(systemName: "ellipsis.circle") }
                    .accessibilityLabel("Report this item")
                }
                if item.ownerID == LocalIdentity.userID {
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            if item.stateEnum == .resolved { Button("Reopen report") { manageReport(reopen: true) } }
                            else { Button("Mark resolved") { manageReport(reopen: false) } }
                            Button("Delete report", role: .destructive) { deleteReport() }
                        } label: { Image(systemName: "slider.horizontal.3") }
                        .accessibilityLabel("Manage your report")
                    }
                }
            }
            .sheet(isPresented: $showingClaimFlow) {
                OwnershipClaimView(item: item, mode: .claim)
            }
            .sheet(isPresented: $showingFoundReport) {
                OwnershipClaimView(item: item, mode: .foundIt)
            }
            .alert("Report submitted", isPresented: Binding(get: { moderationMessage != nil }, set: { if !$0 { moderationMessage = nil } })) { Button("OK", role: .cancel) {} } message: { Text(moderationMessage ?? "") }
            .alert("Report updated", isPresented: Binding(get: { managementMessage != nil }, set: { if !$0 { managementMessage = nil } })) { Button("OK", role: .cancel) {} } message: { Text(managementMessage ?? "") }
        }
    }

    private func submitModeration(_ reason: ModerationReason) {
        do { try ModerationRepository(context: modelContext).submit(targetID: item.id, reason: reason); moderationMessage = "Thanks. This report is stored locally for review." }
        catch { moderationMessage = error.localizedDescription }
    }

    private func manageReport(reopen: Bool) { do { let repository = ReportRepository(context: modelContext); if reopen { try repository.reopen(item); managementMessage = "The report is active again." } else { try repository.resolve(item); managementMessage = "The report was marked resolved." } } catch { managementMessage = error.localizedDescription } }
    private func deleteReport() { do { try ReportRepository(context: modelContext).delete(item); dismiss() } catch { managementMessage = error.localizedDescription } }

    // MARK: - Hero

    private var heroSection: some View {
        ZStack {
            if let data = item.photoData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, minHeight: 280, maxHeight: 280)
                    .clipped()
            } else {
                ZStack {
                    Color(.tertiarySystemGroupedBackground)
                        .frame(height: 280)
                    Image(systemName: item.categoryEnum.icon)
                        .font(.system(size: 72, weight: .thin))
                        .foregroundStyle(.quaternary)
                        .symbolRenderingMode(.hierarchical)
                }
            }
        }
        .frame(height: 280)
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                StatusBadge(reportType: item.reportTypeEnum)
                Text(item.categoryEnum.rawValue)
                    .font(AppTheme.Font.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color(.tertiarySystemGroupedBackground))
                    .clipShape(Capsule())
                Spacer()
                ItemStatusBadge(status: item.statusEnum)
            }

            Text(item.name)
                .font(AppTheme.Font.title1)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Details Card

    private var detailsCard: some View {
        VStack(spacing: 0) {
            detailRow(icon: "location.fill", label: "Location", value: item.approximateLocation)
            Divider().padding(.horizontal, 16)
            detailRow(icon: "calendar", label: item.reportTypeEnum == .lost ? "Lost on" : "Found on", value: item.occurredAt.dayString)
            Divider().padding(.horizontal, 16)
            detailRow(icon: "clock", label: "Reported", value: item.createdAt.relativeDescription)
        }
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.lg))
    }

    func detailRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.secondary)
                .frame(width: 20)
            Text(label)
                .font(AppTheme.Font.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(AppTheme.Font.subheadline)
                .fontWeight(.medium)
                .multilineTextAlignment(.trailing)
                .lineLimit(1)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Description

    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("DESCRIPTION")
                .font(AppTheme.Font.overline)
                .foregroundStyle(.secondary)
            Text(item.itemDescription)
                .font(AppTheme.Font.body)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Map

    func mapSection(coord: CLLocationCoordinate2D) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("APPROXIMATE LOCATION")
                .font(AppTheme.Font.overline)
                .foregroundStyle(.secondary)

            Map {
                Annotation(item.approximateLocation, coordinate: coord) {
                    ZStack {
                        Circle()
                            .fill(AppTheme.color(for: item.reportTypeEnum).opacity(0.2))
                            .frame(width: 60, height: 60)
                        Circle()
                            .fill(AppTheme.color(for: item.reportTypeEnum))
                            .frame(width: 20, height: 20)
                        Circle()
                            .strokeBorder(.white, lineWidth: 2)
                            .frame(width: 20, height: 20)
                    }
                }
            }
            .mapStyle(.standard)
            .frame(height: 180)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.lg))
            .disabled(true)
            .allowsHitTesting(false)

            Text("Approximate location only. Exact address is private.")
                .font(AppTheme.Font.caption)
                .foregroundStyle(.tertiary)
        }
    }

    // MARK: - CTA

    private var ctaSection: some View {
        VStack(spacing: 12) {
            if item.reportTypeEnum == .found {
                Button {
                    showingClaimFlow = true
                } label: {
                    Label("I think this is mine", systemImage: "hand.raised.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryButtonStyle())
            } else {
                Button {
                    showingFoundReport = true
                } label: {
                    Label("I found this item", systemImage: "checkmark.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryButtonStyle())
            }
        }
    }
}

// MARK: - OwnershipClaimView

enum ClaimMode { case claim, foundIt }

struct OwnershipClaimView: View {
    let item: ItemReport
    let mode: ClaimMode
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var verificationAnswer: String = ""
    @State private var step: Int = 1
    @State private var verificationResult: ClaimStatus?
    @State private var verifiedClaim: ClaimRequest?
    @State private var showingCoordination = false
    @State private var challengeQuestion = "What is something only the owner would know about this item?"
    @State private var verificationError: String?
    @State private var checkScale: CGFloat = 0

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()

                switch step {
                case 1: disclaimerStep
                case 2: verificationStep
                case 3: verifiedStep
                default: EmptyView()
                }
            }
            .navigationTitle(mode == .claim ? "Prove It's Yours" : "I Found This")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(.secondary)
                }
            }
            .task {
                challengeQuestion = (try? PrivateVerificationStore.load(for: item.id))?.question ?? challengeQuestion
            }
            .alert("Verification unavailable", isPresented: Binding(get: { verificationError != nil }, set: { if !$0 { verificationError = nil } })) { Button("OK", role: .cancel) {} } message: { Text(verificationError ?? "") }
            .sheet(isPresented: $showingCoordination) {
                if let verifiedClaim { ReturnCoordinationView(claim: verifiedClaim, report: item) }
            }
        }
    }

    // MARK: Step 1: Disclaimer

    private var disclaimerStep: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            Spacer()

            Image(systemName: "lock.shield")
                .font(.system(size: 56, weight: .thin))
                .foregroundStyle(Color.accentColor)
                .symbolRenderingMode(.hierarchical)

            VStack(spacing: 8) {
                Text(mode == .claim ? "Verify ownership" : "Report as finder")
                    .font(AppTheme.Font.title2)
                Text(mode == .claim
                     ? "To protect the rightful owner, we'll ask you a question based on the finder's private notes. Only the real owner would know the answer."
                     : "Your contact details will stay private. The system will connect you with the owner if verified."
                )
                .font(AppTheme.Font.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppTheme.Spacing.lg)
            }

            Spacer()

            VStack(spacing: 12) {
                Button("Continue") {
                    withAnimation { step = 2 }
                }
                .buttonStyle(PrimaryButtonStyle())

                Button("Cancel") { dismiss() }
                    .buttonStyle(SecondaryButtonStyle())
            }
            .padding(.horizontal, AppTheme.Spacing.lg)
            .padding(.bottom, AppTheme.Spacing.lg)
        }
    }

    // MARK: Step 2: Verification

    private var verificationStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Answer a question")
                        .font(AppTheme.Font.title2)
                    Text("The finder left a private note. Only the owner would know this.")
                        .font(AppTheme.Font.callout)
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("QUESTION")
                        .font(AppTheme.Font.overline)
                        .foregroundStyle(.secondary)

                    Text(challengeQuestion)
                        .font(AppTheme.Font.headline)
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.md))
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("YOUR ANSWER")
                        .font(AppTheme.Font.overline)
                        .foregroundStyle(.secondary)

                    TextField("Type your answer here…", text: $verificationAnswer, axis: .vertical)
                        .lineLimit(3...6)
                        .formFieldStyle()
                }

                Button("Submit Verification") {
                    verifyAnswer()
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(verificationAnswer.trimmed.isEmpty)
                .opacity(verificationAnswer.trimmed.isEmpty ? 0.45 : 1)
            }
            .padding(AppTheme.Spacing.lg)
        }
    }

    // MARK: Step 3: Verified

    private var verifiedStep: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            Spacer()

            ZStack {
                Circle()
                    .fill(AppTheme.Color.highConfidence.opacity(0.12))
                    .frame(width: 110, height: 110)
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 52))
                    .foregroundStyle(AppTheme.Color.highConfidence)
                    .scaleEffect(checkScale)
            }

            VStack(spacing: 8) {
                Text(verificationResult == .verified ? "Ownership verified" : "Verification needs review")
                    .font(AppTheme.Font.title1)
                Text(verificationResult == .verified ? "Your claim was verified locally. You can now arrange a safe campus return." : "Your answer was recorded for review. Do not share private details publicly.")
                    .font(AppTheme.Font.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppTheme.Spacing.lg)
            }

            Spacer()

            Button(verificationResult == .verified ? "Arrange Return" : "Done") {
                if verificationResult == .verified { showingCoordination = true } else { dismiss() }
            }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal, AppTheme.Spacing.lg)
                .padding(.bottom, AppTheme.Spacing.lg)
        }
        .onAppear {
            withAnimation(.spring(duration: 0.5, bounce: 0.4)) {
                checkScale = 1
            }
        }
    }

    private func verifyAnswer() {
        do {
            guard item.ownerID != LocalIdentity.userID else { verificationError = "You cannot submit an ownership claim for your own report."; return }
            let claim = try ClaimRepository(context: modelContext).submit(report: item, answer: verificationAnswer)
            verifiedClaim = claim
            verificationResult = claim.statusEnum
            switch claim.statusEnum {
            case .rejected:
                verificationError = "That answer doesn’t match the private verification details. Please try again with a specific identifying detail."
            case .verified, .needsReview:
                withAnimation { step = 3 }
            case .pending, .cancelled:
                verificationError = "The claim could not be verified yet."
            }
        } catch {
            verificationError = error.localizedDescription
        }
    }
}

#Preview {
    ItemDetailView(item: ItemReport(ownerID: LocalIdentity.userID, reportType: .found, name: "Sample item", category: .other, itemDescription: "", publicLocationName: "Campus"))
}
