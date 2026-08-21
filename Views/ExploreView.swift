import SwiftUI
import MapKit

// MARK: - ExploreView

struct ExploreView: View {

    @State private var searchText: String = ""
    @State private var selectedFilter: FilterOption = .all
    @State private var selectedCategory: ItemCategory? = nil
    @State private var viewMode: ViewMode = .list
    @State private var selectedItem: MockItemReport? = nil

    enum ViewMode: String, CaseIterable {
        case list = "List"
        case map = "Map"

        var icon: String {
            switch self {
            case .list: return "list.bullet"
            case .map: return "map"
            }
        }
    }

    enum FilterOption: String, CaseIterable, Identifiable {
        case all = "All"
        case lost = "Lost"
        case found = "Found"
        var id: String { rawValue }
    }

    private var filteredItems: [MockItemReport] {
        var items = MockData.allItems

        // Filter by type
        switch selectedFilter {
        case .lost: items = items.filter { $0.reportType == .lost }
        case .found: items = items.filter { $0.reportType == .found }
        case .all: break
        }

        // Filter by category
        if let cat = selectedCategory {
            items = items.filter { $0.category == cat }
        }

        // Search
        let query = searchText.trimmed.lowercased()
        if !query.isEmpty {
            items = items.filter {
                $0.name.lowercased().contains(query) ||
                $0.itemDescription.lowercased().contains(query) ||
                $0.locationName.lowercased().contains(query) ||
                $0.category.rawValue.lowercased().contains(query)
            }
        }

        return items
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()

                VStack(spacing: 0) {
                    // Controls
                    controlsSection
                        .padding(.horizontal, AppTheme.Spacing.lg)
                        .padding(.vertical, AppTheme.Spacing.sm)

                    // Category chips
                    categoryChips

                    // Content
                    Group {
                        if viewMode == .list {
                            listView
                        } else {
                            mapView
                        }
                    }
                    .animation(.easeInOut(duration: 0.2), value: viewMode)
                }
            }
            .navigationTitle("Explore")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: "Search lost & found")
            .sheet(item: $selectedItem) { item in
                ItemDetailView(item: item)
            }
        }
    }

    // MARK: - Controls

    private var controlsSection: some View {
        HStack(spacing: 10) {
            // Type filter
            HStack(spacing: 4) {
                ForEach(FilterOption.allCases) { option in
                    Button(option.rawValue) {
                        selectedFilter = option
                    }
                    .font(AppTheme.Font.subheadline)
                    .fontWeight(selectedFilter == option ? .semibold : .regular)
                    .foregroundStyle(selectedFilter == option ? .primary : .secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(selectedFilter == option ? Color(.secondarySystemGroupedBackground) : .clear)
                    .clipShape(Capsule())
                }
            }
            .padding(3)
            .background(Color(.systemFill))
            .clipShape(Capsule())

            Spacer()

            // View mode toggle
            HStack(spacing: 0) {
                ForEach(ViewMode.allCases, id: \.self) { mode in
                    Button {
                        viewMode = mode
                    } label: {
                        Image(systemName: mode.icon)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(viewMode == mode ? .primary : .secondary)
                            .frame(width: 36, height: 32)
                    }
                }
            }
            .background(Color(.systemFill))
            .clipShape(Capsule())
        }
    }

    // MARK: - Category Chips

    private var categoryChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // "All" chip
                Button {
                    selectedCategory = nil
                } label: {
                    Text("All")
                        .font(AppTheme.Font.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(selectedCategory == nil ? .white : .secondary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(selectedCategory == nil ? Color.primary : Color(.secondarySystemGroupedBackground))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)

                ForEach(ItemCategory.allCases) { cat in
                    Button {
                        selectedCategory = selectedCategory == cat ? nil : cat
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: cat.icon)
                                .font(.system(size: 11))
                            Text(cat.rawValue)
                                .font(AppTheme.Font.caption)
                                .fontWeight(.medium)
                        }
                        .foregroundStyle(selectedCategory == cat ? .white : .secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(selectedCategory == cat ? Color.primary : Color(.secondarySystemGroupedBackground))
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, AppTheme.Spacing.lg)
            .padding(.vertical, AppTheme.Spacing.xs)
        }
    }

    // MARK: - List View

    private var listView: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                if filteredItems.isEmpty {
                    if searchText.isEmpty {
                        EmptyStateView.noFoundItems
                            .frame(height: 300)
                    } else {
                        EmptyStateView.searchNoResults
                            .frame(height: 300)
                    }
                } else {
                    ForEach(filteredItems) { item in
                        ItemCard(item: item)
                            .onTapGesture {
                                selectedItem = item
                            }
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }
                }
            }
            .padding(.horizontal, AppTheme.Spacing.lg)
            .padding(.vertical, AppTheme.Spacing.sm)
            .animation(.spring(duration: 0.35), value: filteredItems.map { $0.id })
        }
        .scrollIndicators(.hidden)
    }

    // MARK: - Map View

    @State private var mapPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 37.8719, longitude: -122.2585),
            span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
        )
    )

    private var mapView: some View {
        Map(position: $mapPosition) {
            ForEach(filteredItems.filter { $0.coordinate != nil }) { item in
                let coord = item.coordinate!
                Annotation(item.name, coordinate: coord) {
                    Button {
                        selectedItem = item
                    } label: {
                        ZStack {
                            Circle()
                                .fill(AppTheme.color(for: item.reportType))
                                .frame(width: 34, height: 34)
                            Image(systemName: item.category.icon)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(.white)
                        }
                        .shadow(radius: 3)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .mapStyle(.standard(elevation: .realistic))
        .ignoresSafeArea(edges: .bottom)
    }
}

#Preview {
    ExploreView()
}
