import SwiftUI
import PhotosUI
import MapKit
import CoreLocation

// MARK: - ReportMode (updated)

enum ReportMode {
    case lost
    case found

    var title: String {
        switch self {
        case .lost: return "I Lost Something"
        case .found: return "I Found Something"
        }
    }

    var accentColor: Color {
        AppTheme.color(for: reportType)
    }

    var reportType: ReportType {
        switch self {
        case .lost: return .lost
        case .found: return .found
        }
    }

    var buttonTitle: String {
        switch self {
        case .lost: return "Post Lost Item"
        case .found: return "Post Found Item"
        }
    }

    var successMessage: String {
        switch self {
        case .lost: return "Your report is live. We'll notify you if something matches."
        case .found: return "Thank you for helping return something that matters."
        }
    }

    var successTitle: String {
        switch self {
        case .lost: return "Lost item reported."
        case .found: return "Found item posted."
        }
    }

    var waitingStatus: String {
        switch self {
        case .lost: return "Searching for matches…"
        case .found: return "Waiting for owner"
        }
    }
}

// MARK: - ReportViewModel

@Observable
final class ReportViewModel {
    var step: Int = 1
    var totalSteps: Int = 5

    // Step 1 — What
    var name: String = ""
    var category: ItemCategory = .other
    var itemDescription: String = ""
    var selectedPhoto: PhotosPickerItem? = nil
    var photoData: Data? = nil
    var suggestedCategory: ItemCategory? = nil
    var suggestedColorHint: String = ""
    var analysisInProgress: Bool = false

    // Step 2 — Where
    var locationName: String = ""
    var pickedCoordinate: CLLocationCoordinate2D? = nil
    var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 37.8719, longitude: -122.2585),
            span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
        )
    )

    // Step 3 — When
    var date: Date = Date()

    // Step 4 — Private details
    var privateDetails: String = ""

    // State
    var isSubmitting: Bool = false
    var showSuccess: Bool = false

    var canProceedStep1: Bool {
        !name.trimmed.isEmpty && !itemDescription.trimmed.isEmpty
    }

    var canProceedStep2: Bool {
        !locationName.trimmed.isEmpty || pickedCoordinate != nil
    }

    var progress: Double {
        Double(step) / Double(totalSteps)
    }
}

// MARK: - ReportItemView

struct ReportItemView: View {
    let mode: ReportMode

    @State private var vm = ReportViewModel()
    @State private var showingCamera = false
    @State private var showingPhotoOptions = false
    @Environment(\.dismiss) private var dismiss

    private let imageAnalyzer = ImageAnalysisService()

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()

                VStack(spacing: 0) {
                    // Progress bar
                    progressBar

                    // Step content
                    stepContent
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .animation(.easeInOut(duration: 0.3), value: vm.step)

                    // Navigation buttons
                    navigationButtons
                        .padding(.horizontal, AppTheme.Spacing.lg)
                        .padding(.bottom, AppTheme.Spacing.lg)
                }
            }
            .navigationTitle(mode.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(.secondary)
                }
            }
            .sheet(isPresented: $showingCamera) {
                CameraView { image in
                    vm.photoData = image.jpegData(compressionQuality: 0.85)
                    analyzePhoto()
                }
            }
            .confirmationDialog("Add a photo", isPresented: $showingPhotoOptions, titleVisibility: .visible) {
                Button("Take Photo") { showingCamera = true }
                Button("Choose from Library") { }
                Button("Cancel", role: .cancel) {}
            }
            .task(id: vm.selectedPhoto) {
                if let item = vm.selectedPhoto {
                    do {
                        vm.photoData = try await item.loadTransferable(type: Data.self)
                        analyzePhoto()
                    } catch { }
                }
            }
            .fullScreenCover(isPresented: $vm.showSuccess) {
                ReportSuccessView(mode: mode) {
                    dismiss()
                }
            }
        }
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        VStack(spacing: 8) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color(.systemFill))
                        .frame(height: 3)

                    Rectangle()
                        .fill(mode.accentColor)
                        .frame(width: geo.size.width * vm.progress, height: 3)
                        .animation(.spring(duration: 0.4), value: vm.progress)
                }
            }
            .frame(height: 3)

            HStack {
                Text("Step \(vm.step) of \(vm.totalSteps)")
                    .font(AppTheme.Font.caption)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.horizontal, AppTheme.Spacing.lg)
        }
        .padding(.top, AppTheme.Spacing.sm)
        .padding(.bottom, AppTheme.Spacing.md)
    }

    // MARK: - Step Content

    @ViewBuilder
    private var stepContent: some View {
        switch vm.step {
        case 1: step1View
        case 2: step2View
        case 3: step3View
        case 4: step4View
        case 5: step5ReviewView
        default: EmptyView()
        }
    }

    // MARK: - Navigation Buttons

    private var navigationButtons: some View {
        HStack(spacing: 12) {
            if vm.step > 1 {
                Button {
                    withAnimation(.spring(duration: 0.3)) { vm.step -= 1 }
                } label: {
                    HStack {
                        Image(systemName: "arrow.left")
                        Text("Back")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(SecondaryButtonStyle())
            }

            if vm.step < vm.totalSteps {
                Button {
                    withAnimation(.spring(duration: 0.3)) { vm.step += 1 }
                } label: {
                    HStack {
                        Text("Continue")
                        Image(systemName: "arrow.right")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(!canProceedCurrentStep)
                .opacity(canProceedCurrentStep ? 1 : 0.45)
            } else {
                Button {
                    submitReport()
                } label: {
                    HStack {
                        if vm.isSubmitting {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text(mode.buttonTitle)
                            Image(systemName: "checkmark")
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(vm.isSubmitting)
            }
        }
    }

    private var canProceedCurrentStep: Bool {
        switch vm.step {
        case 1: return vm.canProceedStep1
        case 2: return vm.canProceedStep2
        default: return true
        }
    }

    // MARK: - Submit

    private func submitReport() {
        vm.isSubmitting = true
        Task {
            try? await Task.sleep(for: .seconds(1.2))
            vm.isSubmitting = false
            vm.showSuccess = true
        }
    }

    private func analyzePhoto() {
        guard let data = vm.photoData else { return }
        vm.analysisInProgress = true
        Task {
            let result = await imageAnalyzer.analyze(imageData: data)
            if let cat = result.suggestedCategory {
                vm.suggestedCategory = cat
                if vm.category == .other { vm.category = cat }
            }
            if let color = result.dominantColors.first {
                vm.suggestedColorHint = color
            }
            vm.analysisInProgress = false
        }
    }
}

// MARK: - Step 1: What

extension ReportItemView {
    var step1View: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                stepHeader(
                    title: mode == .lost ? "What did you lose?" : "What did you find?",
                    subtitle: mode == .lost
                        ? "Give us a few details and we'll help you find it."
                        : "Someone may be looking for exactly this."
                )

                // Photo
                photoSection

                // AI Suggestion banner
                if vm.analysisInProgress {
                    analysisProgressBanner
                }
                if let suggested = vm.suggestedCategory, !vm.analysisInProgress {
                    analysisSuggestionBanner(category: suggested)
                }

                // Name
                formField(label: "ITEM NAME") {
                    TextField("e.g. Black AirPods Pro Case", text: $vm.name)
                        .textInputAutocapitalization(.words)
                        .formFieldStyle()
                }

                // Category
                formField(label: "CATEGORY") {
                    categoryPicker
                }

                // Description
                formField(label: "DESCRIPTION") {
                    ZStack(alignment: .topLeading) {
                        RoundedRectangle(cornerRadius: AppTheme.Radius.md)
                            .fill(Color(.secondarySystemGroupedBackground))

                        if vm.itemDescription.isEmpty {
                            Text(mode == .lost
                                 ? "Describe it like you remember it — color, size, brand, any markings…"
                                 : "Describe what you found — color, size, condition, any details…")
                                .font(AppTheme.Font.body)
                                .foregroundStyle(.tertiary)
                                .padding(16)
                                .allowsHitTesting(false)
                        }

                        TextEditor(text: $vm.itemDescription)
                            .scrollContentBackground(.hidden)
                            .padding(12)
                            .frame(minHeight: 120)
                    }
                }
            }
            .padding(.horizontal, AppTheme.Spacing.lg)
            .padding(.bottom, AppTheme.Spacing.md)
        }
    }

    var photoSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("PHOTO")
                .font(AppTheme.Font.overline)
                .foregroundStyle(.secondary)

            PhotosPicker(selection: $vm.selectedPhoto, matching: .images) {
                ZStack {
                    RoundedRectangle(cornerRadius: AppTheme.Radius.lg)
                        .fill(Color(.secondarySystemGroupedBackground))
                        .frame(height: 200)

                    if let data = vm.photoData, let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity, minHeight: 200, maxHeight: 200)
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.lg))
                            .overlay(alignment: .topTrailing) {
                                Button {
                                    vm.photoData = nil
                                    vm.selectedPhoto = nil
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 24))
                                        .foregroundStyle(.white)
                                        .shadow(radius: 4)
                                }
                                .padding(10)
                            }
                    } else {
                        VStack(spacing: 10) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 28, weight: .medium))
                                .foregroundStyle(.secondary)
                            Text("Add a photo")
                                .font(AppTheme.Font.headline)
                            Text("Makes matching much easier")
                                .font(AppTheme.Font.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .buttonStyle(.plain)
        }
    }

    var categoryPicker: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4),
            spacing: 8
        ) {
            ForEach(ItemCategory.allCases) { cat in
                Button {
                    vm.category = cat
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: cat.icon)
                            .font(.system(size: 20, weight: .medium))
                        Text(cat.rawValue)
                            .font(.system(size: 11, weight: .medium))
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(vm.category == cat
                        ? mode.accentColor.opacity(0.15)
                        : Color(.secondarySystemGroupedBackground))
                    .foregroundStyle(vm.category == cat ? mode.accentColor : .secondary)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.sm))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.Radius.sm)
                            .strokeBorder(vm.category == cat ? mode.accentColor : .clear, lineWidth: 1.5)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    var analysisProgressBanner: some View {
        HStack(spacing: 10) {
            ProgressView()
                .scaleEffect(0.85)
            Text("Analyzing your photo…")
                .font(AppTheme.Font.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.sm))
    }

    func analysisSuggestionBanner(category: ItemCategory) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "sparkles")
                .foregroundStyle(Color.accentColor)
            VStack(alignment: .leading, spacing: 2) {
                Text("Suggested category: **\(category.rawValue)**")
                    .font(AppTheme.Font.subheadline)
                Text("This is a suggestion — you can change it above.")
                    .font(AppTheme.Font.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.accentColor.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.sm))
    }
}

// MARK: - Step 2: Where

extension ReportItemView {
    var step2View: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            stepHeader(
                title: mode == .lost ? "Where did you lose it?" : "Where did you find it?",
                subtitle: "We use approximate locations — your exact address is never shared."
            )
            .padding(.horizontal, AppTheme.Spacing.lg)

            // Map
            Map(position: $vm.cameraPosition, interactionModes: .all) {
                if let coord = vm.pickedCoordinate {
                    Annotation(vm.locationName.isEmpty ? "Selected location" : vm.locationName, coordinate: coord) {
                        ZStack {
                            Circle()
                                .fill(mode.accentColor)
                                .frame(width: 30, height: 30)
                            Image(systemName: "mappin.fill")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                    }
                }
            }
            .mapStyle(.standard(elevation: .realistic))
            .frame(height: 240)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.lg))
            .overlay(alignment: .bottomTrailing) {
                Button {
                    useCurrentLocation()
                } label: {
                    Image(systemName: "location.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.white)
                        .frame(width: 40, height: 40)
                        .background(mode.accentColor)
                        .clipShape(Circle())
                        .shadow(radius: 4)
                }
                .padding(12)
            }
            .padding(.horizontal, AppTheme.Spacing.lg)
            .onTapGesture(coordinateSpace: .local) { location in
                // Tap on map to place pin — simplified; full implementation uses MapReader
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("LOCATION NAME")
                    .font(AppTheme.Font.overline)
                    .foregroundStyle(.secondary)

                HStack(spacing: 12) {
                    Image(systemName: "location.fill")
                        .foregroundStyle(mode.accentColor)
                    TextField("e.g. Main Library, 2nd Floor", text: $vm.locationName)
                        .textInputAutocapitalization(.words)
                }
                .formFieldStyle()
            }
            .padding(.horizontal, AppTheme.Spacing.lg)

            Spacer()
        }
    }

    private func useCurrentLocation() {
        // For MVP: set a nearby point on campus
        vm.pickedCoordinate = CLLocationCoordinate2D(latitude: 37.8719, longitude: -122.2585)
        vm.cameraPosition = .region(MKCoordinateRegion(
            center: vm.pickedCoordinate!,
            span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
        ))
        if vm.locationName.isEmpty {
            vm.locationName = "Current Location"
        }
    }
}

// MARK: - Step 3: When

extension ReportItemView {
    var step3View: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
            stepHeader(
                title: mode == .lost ? "When did you lose it?" : "When did you find it?",
                subtitle: "An accurate time helps us narrow the search."
            )

            VStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("DATE & TIME")
                        .font(AppTheme.Font.overline)
                        .foregroundStyle(.secondary)

                    DatePicker(
                        "",
                        selection: $vm.date,
                        in: ...Date(),
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .datePickerStyle(.graphical)
                    .accentColor(mode.accentColor)
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.lg))
                }
            }

            Spacer()
        }
        .padding(.horizontal, AppTheme.Spacing.lg)
    }
}

// MARK: - Step 4: Private Details

extension ReportItemView {
    var step4View: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                stepHeader(
                    title: "Add identifying details",
                    subtitle: "Private information that only the real owner would know. This is NEVER shown publicly."
                )

                // Privacy notice
                HStack(spacing: 10) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(Color.accentColor)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Your information is private.")
                            .font(AppTheme.Font.subheadline)
                            .fontWeight(.semibold)
                        Text("Only used for ownership verification. Never shared publicly.")
                            .font(AppTheme.Font.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(14)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.md))

                formField(label: "PRIVATE IDENTIFYING DETAILS") {
                    ZStack(alignment: .topLeading) {
                        RoundedRectangle(cornerRadius: AppTheme.Radius.md)
                            .fill(Color(.secondarySystemGroupedBackground))

                        if vm.privateDetails.isEmpty {
                            Text(mode == .lost
                                 ? "e.g. \"There's a purple sticker on the inside lid\" or \"My initials are scratched on the back\""
                                 : "e.g. \"Has a sticker on the inside\" or \"Specific marking I noticed\"")
                                .font(AppTheme.Font.body)
                                .foregroundStyle(.tertiary)
                                .padding(16)
                                .allowsHitTesting(false)
                        }

                        TextEditor(text: $vm.privateDetails)
                            .scrollContentBackground(.hidden)
                            .padding(12)
                            .frame(minHeight: 120)
                    }
                }

                Text("This step is optional but strongly recommended.")
                    .font(AppTheme.Font.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, AppTheme.Spacing.lg)
            .padding(.bottom, AppTheme.Spacing.md)
        }
    }
}

// MARK: - Step 5: Review

extension ReportItemView {
    var step5ReviewView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                stepHeader(
                    title: "Review your report",
                    subtitle: "Everything look right? Tap below to post."
                )

                // Photo preview
                if let data = vm.photoData, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity, minHeight: 200, maxHeight: 220)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.lg))
                }

                // Summary card
                VStack(spacing: 0) {
                    reviewRow(label: "Type", value: mode.reportType.displayName)
                    Divider().padding(.horizontal, 16)
                    reviewRow(label: "Item", value: vm.name.isEmpty ? "Not specified" : vm.name)
                    Divider().padding(.horizontal, 16)
                    reviewRow(label: "Category", value: vm.category.rawValue)
                    Divider().padding(.horizontal, 16)
                    reviewRow(label: "Location", value: vm.locationName.isEmpty ? "Not specified" : vm.locationName)
                    Divider().padding(.horizontal, 16)
                    reviewRow(label: "Date", value: vm.date.dayString)
                    Divider().padding(.horizontal, 16)
                    reviewRow(label: "Description", value: vm.itemDescription, multiline: true)
                    Divider().padding(.horizontal, 16)
                    reviewRow(label: "Private details", value: vm.privateDetails.isEmpty ? "None added" : "✓ Added (private)", subtle: vm.privateDetails.isEmpty)
                }
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.lg))

                Text("After posting, your report will be visible in the Explore tab. Private details are never shown.")
                    .font(AppTheme.Font.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, AppTheme.Spacing.lg)
            .padding(.bottom, AppTheme.Spacing.md)
        }
    }

    func reviewRow(label: String, value: String, multiline: Bool = false, subtle: Bool = false) -> some View {
        HStack(alignment: multiline ? .top : .center, spacing: 16) {
            Text(label)
                .font(AppTheme.Font.subheadline)
                .foregroundStyle(.secondary)
                .frame(width: 100, alignment: .leading)
            Text(value)
                .font(AppTheme.Font.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(subtle ? .secondary : .primary)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: multiline)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Shared Helpers

extension ReportItemView {
    func stepHeader(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(AppTheme.Font.title1)
                .fixedSize(horizontal: false, vertical: true)
            Text(subtitle)
                .font(AppTheme.Font.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    func formField<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(AppTheme.Font.overline)
                .foregroundStyle(.secondary)
            content()
        }
    }
}

// MARK: - Form Field Style

struct FormFieldStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(AppTheme.Font.body)
            .padding(16)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.md))
    }
}

extension View {
    func formFieldStyle() -> some View {
        modifier(FormFieldStyle())
    }
}

// MARK: - Report Hub (for Report tab)

struct ReportHubView: View {
    @State private var showingLost = false
    @State private var showingFound = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()
                VStack(spacing: AppTheme.Spacing.xl) {
                    Spacer()
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Make a Report")
                            .font(AppTheme.Font.largeTitle)
                        Text("Help yourself and others by reporting lost or found items.")
                            .font(AppTheme.Font.callout)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, AppTheme.Spacing.lg)

                    VStack(spacing: 14) {
                        HomeActionCard(
                            icon: "magnifyingglass",
                            title: "Lost Something?",
                            subtitle: "Tell us what you're looking for.",
                            buttonTitle: "Report Lost Item",
                            accentColor: AppTheme.Color.lost
                        ) { showingLost = true }

                        HomeActionCard(
                            icon: "hand.raised.fill",
                            title: "Found Something?",
                            subtitle: "Help someone get it back.",
                            buttonTitle: "Report Found Item",
                            accentColor: AppTheme.Color.found
                        ) { showingFound = true }
                    }
                    .padding(.horizontal, AppTheme.Spacing.lg)

                    Spacer()
                }
            }
            .navigationTitle("Report")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingLost) { ReportItemView(mode: .lost) }
            .sheet(isPresented: $showingFound) { ReportItemView(mode: .found) }
        }
    }
}

// MARK: - Report Success View

struct ReportSuccessView: View {
    let mode: ReportMode
    let onDone: () -> Void

    @State private var checkmarkScale: CGFloat = 0
    @State private var textOpacity: CGFloat = 0
    @State private var ringScale: CGFloat = 0

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            VStack(spacing: AppTheme.Spacing.lg) {
                Spacer()

                ZStack {
                    Circle()
                        .strokeBorder(mode.accentColor.opacity(0.2), lineWidth: 2)
                        .frame(width: 120, height: 120)
                        .scaleEffect(ringScale)

                    Circle()
                        .fill(mode.accentColor.opacity(0.12))
                        .frame(width: 100, height: 100)

                    Image(systemName: "checkmark")
                        .font(.system(size: 44, weight: .bold))
                        .foregroundStyle(mode.accentColor)
                        .scaleEffect(checkmarkScale)
                }

                VStack(spacing: 8) {
                    Text(mode.successTitle)
                        .font(AppTheme.Font.title1)
                        .multilineTextAlignment(.center)

                    Text(mode.successMessage)
                        .font(AppTheme.Font.callout)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, AppTheme.Spacing.xl)

                    if mode == .found {
                        Text(mode.waitingStatus)
                            .font(AppTheme.Font.subheadline)
                            .foregroundStyle(mode.accentColor)
                            .padding(.top, 4)
                    }
                }
                .opacity(textOpacity)

                Spacer()

                Button("Done", action: onDone)
                    .buttonStyle(PrimaryButtonStyle())
                    .padding(.horizontal, AppTheme.Spacing.lg)
                    .padding(.bottom, AppTheme.Spacing.lg)
                    .opacity(textOpacity)
            }
        }
        .onAppear {
            withAnimation(.spring(duration: 0.5, bounce: 0.4)) {
                checkmarkScale = 1
                ringScale = 1
            }
            withAnimation(.easeIn(duration: 0.4).delay(0.3)) {
                textOpacity = 1
            }
        }
    }
}

#Preview {
    ReportItemView(mode: .lost)
}
