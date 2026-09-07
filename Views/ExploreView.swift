import SwiftUI
import SwiftData
import MapKit
import CoreLocation

struct ExploreView: View {
    @Query(sort: \ItemReport.createdAt, order: .reverse) private var reports: [ItemReport]
    @Environment(LocationService.self) private var locationService
    @State private var searchText = ""
    @State private var selectedFilter: FilterOption = .all
    @State private var selectedCategory: ItemCategory?
    @State private var selectedState: ReportState = .active
    @State private var viewMode: ViewMode = .list
    @State private var selectedItem: ItemReport?
    @State private var mapPosition = MapCameraPosition.automatic
    @State private var nearbyOnly = false

    enum ViewMode: String, CaseIterable { case list = "List", map = "Map"; var icon: String { self == .list ? "list.bullet" : "map" } }
    enum FilterOption: String, CaseIterable, Identifiable { case all = "All", lost = "Lost", found = "Found"; var id: String { rawValue } }

    private var filteredItems: [ItemReport] {
        reports.filter { report in
            let query = searchText.trimmed.lowercased()
            let typeOK = selectedFilter == .all || report.reportType == selectedFilter.rawValue.lowercased()
            let categoryOK = selectedCategory == nil || report.categoryEnum == selectedCategory
            let stateOK = selectedState == .active ? report.isActive : report.stateEnum == selectedState
            let textOK = query.isEmpty || [report.name, report.itemDescription, report.approximateLocation, report.category].contains { $0.lowercased().contains(query) }
            let distanceOK = !nearbyOnly || (locationService.currentLocation.flatMap { current in report.coordinate.map { current.distance(from: CLLocation(latitude: $0.latitude, longitude: $0.longitude)) <= 500 } } ?? false)
            return typeOK && categoryOK && stateOK && textOK && distanceOK
        }.sorted { left, right in
            guard nearbyOnly, let current = locationService.currentLocation, let l = left.coordinate, let r = right.coordinate else { return left.createdAt > right.createdAt }
            return current.distance(from: CLLocation(latitude: l.latitude, longitude: l.longitude)) < current.distance(from: CLLocation(latitude: r.latitude, longitude: r.longitude))
        }
    }

    var body: some View { NavigationStack { ZStack { Color(.systemGroupedBackground).ignoresSafeArea(); VStack(spacing: 0) {
        controlsSection.padding(.horizontal, AppTheme.Spacing.lg).padding(.vertical, AppTheme.Spacing.sm); categoryChips; insightsSection
        if viewMode == .list { listView } else { mapView }
    }}.navigationTitle("Explore").navigationBarTitleDisplayMode(.large).searchable(text: $searchText, prompt: "Search lost & found").sheet(item: $selectedItem) { ItemDetailView(item: $0) } } }

    private var controlsSection: some View { HStack(spacing: 10) {
        HStack(spacing: 4) { ForEach(FilterOption.allCases) { option in Button(option.rawValue) { selectedFilter = option }.font(AppTheme.Font.subheadline).fontWeight(selectedFilter == option ? .semibold : .regular).foregroundStyle(selectedFilter == option ? .primary : .secondary).padding(.horizontal, 12).padding(.vertical, 6).background(selectedFilter == option ? Color(.secondarySystemGroupedBackground) : .clear).clipShape(Capsule()) } }.padding(3).background(Color(.systemFill)).clipShape(Capsule())
        Spacer(); Button { nearbyOnly.toggle(); if nearbyOnly { locationService.fetchCurrentLocation() } } label: { Image(systemName: nearbyOnly ? "location.fill" : "location") }.accessibilityLabel("Filter nearby reports"); Picker("View", selection: $viewMode) { ForEach(ViewMode.allCases, id: \.self) { Label($0.rawValue, systemImage: $0.icon).tag($0) } }.pickerStyle(.segmented).frame(width: 92)
    }}
    private var categoryChips: some View { ScrollView(.horizontal, showsIndicators: false) { HStack(spacing: 8) {
        chip("All", selected: selectedCategory == nil) { selectedCategory = nil }
        ForEach(ItemCategory.allCases) { category in chip(category.rawValue, selected: selectedCategory == category) { selectedCategory = selectedCategory == category ? nil : category } }
    }.padding(.horizontal, AppTheme.Spacing.lg).padding(.vertical, AppTheme.Spacing.xs) } }
    private func chip(_ text: String, selected: Bool, action: @escaping () -> Void) -> some View { Button(action: action) { Text(text).font(AppTheme.Font.caption).fontWeight(.medium).foregroundStyle(selected ? .white : .secondary).padding(.horizontal, 14).padding(.vertical, 7).background(selected ? Color.primary : Color(.secondarySystemGroupedBackground)).clipShape(Capsule()) }.buttonStyle(.plain) }
    private var listView: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                if filteredItems.isEmpty {
                    EmptyStateView(icon: "magnifyingglass", title: searchText.isEmpty ? "No reports yet." : "No results found.", subtitle: searchText.isEmpty ? "Try adjusting filters or create a report." : "Try different keywords or filters.").frame(height: 300)
                } else {
                    ForEach(filteredItems) { report in
                        ItemCard(item: report).onTapGesture { selectedItem = report }
                    }
                }
            }
            .padding(.horizontal, AppTheme.Spacing.lg)
            .padding(.vertical, AppTheme.Spacing.sm)
        }
        .scrollIndicators(.hidden)
    }
    private var insightsSection: some View { Group { if !reports.isEmpty { let active = reports.filter(\.isActive); let popularCategory = Dictionary(grouping: active, by: \ItemReport.category).max { $0.value.count < $1.value.count }?.key ?? "—"; let popularLocation = Dictionary(grouping: active.filter { !$0.approximateLocation.isEmpty }, by: \ItemReport.approximateLocation).max { $0.value.count < $1.value.count }?.key ?? "—"; HStack(spacing: 8) { Label("Top category: \(popularCategory)", systemImage: "chart.bar"); Label("Active: \(popularLocation)", systemImage: "mappin") }.font(AppTheme.Font.caption).foregroundStyle(.secondary).padding(.horizontal, AppTheme.Spacing.lg).padding(.bottom, 6) } } }
    private var mapView: some View { Map(position: $mapPosition) { ForEach(filteredItems) { report in if let coordinate = report.publicCoordinate { Annotation(report.name, coordinate: coordinate) { Button { selectedItem = report } label: { Image(systemName: report.categoryEnum.icon).font(.caption).foregroundStyle(.white).frame(width: 34, height: 34).background(AppTheme.color(for: report.reportTypeEnum), in: Circle()) }.accessibilityLabel(report.name) } } } }.mapStyle(.standard(elevation: .realistic)).ignoresSafeArea(edges: .bottom) }
}

#Preview { ExploreView().modelContainer(for: ItemReport.self, inMemory: true) }
