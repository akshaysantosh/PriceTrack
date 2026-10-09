import SwiftUI
import SwiftData

struct AllItemsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Query(sort: \GroceryItem.name) private var items: [GroceryItem]
    @State private var searchText = ""
    @State private var showingAddItem = false
    @State private var isSelecting = false
    @State private var selectedItemIDs: Set<UUID> = []
    @State private var showingDeleteConfirm = false
    @State private var selectedCategory: String?

    /// Distinct, non-empty categories currently present, for the filter row. "" is reserved
    /// as the sentinel for the "Uncategorized" chip (nil means "All").
    private var allCategories: [String] {
        let trimmed = items.map { $0.category.trimmingCharacters(in: .whitespaces) }
        return Set(trimmed.filter { !$0.isEmpty }).sorted()
    }

    private var hasUncategorized: Bool {
        items.contains { $0.category.trimmingCharacters(in: .whitespaces).isEmpty }
    }

    private var filteredItems: [GroceryItem] {
        var result = items
        if !searchText.isEmpty {
            result = result.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
        if let selectedCategory {
            result = result.filter { $0.category.trimmingCharacters(in: .whitespaces) == selectedCategory }
        }
        return result
    }

    private var isFiltering: Bool { selectedCategory != nil || !searchText.isEmpty }

    private var countText: String {
        let noun = items.count == 1 ? "item" : "items"
        return isFiltering ? "\(filteredItems.count) of \(items.count) \(noun)" : "\(items.count) \(noun)"
    }

    private var allSelected: Bool {
        !filteredItems.isEmpty && selectedItemIDs.count == filteredItems.count
    }

    private var emptyMessage: String {
        if items.isEmpty {
            return "No items yet. Scan a receipt or add one manually to get started."
        }
        if !searchText.isEmpty {
            return "No items match “\(searchText)”."
        }
        if let selectedCategory {
            return selectedCategory.isEmpty ? "No uncategorized items." : "No items in \(selectedCategory) yet."
        }
        return "No items yet."
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            List {
                header
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: AppSpacing.xs, leading: 0, bottom: AppSpacing.s, trailing: 0))

                if filteredItems.isEmpty {
                    EmptyStateView(
                        symbolName: items.isEmpty ? "cart.badge.plus" : "magnifyingglass",
                        message: emptyMessage
                    )
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                } else {
                    ForEach(filteredItems) { item in
                        row(for: item)
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .contentMargins(.bottom, isSelecting ? AppSpacing.l : 88, for: .scrollContent)

            if !isSelecting {
                FloatingScanButton(onAddManually: { showingAddItem = true })
                    .padding(.trailing, AppSpacing.l + AppSpacing.xs)
                    .padding(.bottom, AppSpacing.l)
            }
        }
        .background(PaperBackground())
        .navigationTitle("All Items")
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .automatic), prompt: "Search items")
        .navigationDestination(for: GroceryItem.self) { item in
            ItemDetailView(item: item)
        }
        .settingsSheet()
        .toolbar {
            if isSelecting {
                ToolbarItem(placement: .topBarLeading) {
                    Button(allSelected ? "Deselect All" : "Select All") {
                        selectedItemIDs = allSelected ? [] : Set(filteredItems.map(\.id))
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    // .bottomBar renders behind this OS's floating tab bar, so the destructive
                    // delete action lives up here instead, next to Done.
                    Button(role: .destructive) {
                        showingDeleteConfirm = true
                    } label: {
                        Text(selectedItemIDs.isEmpty ? "Delete" : "Delete (\(selectedItemIDs.count))")
                    }
                    .disabled(selectedItemIDs.isEmpty)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { isSelecting = false }
                }
            } else if !items.isEmpty {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            isSelecting = true
                        } label: {
                            Label("Select items", systemImage: "checkmark.circle")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundStyle(Color.ink)
                    }
                    .accessibilityLabel("More actions")
                }
            }
        }
        .onChange(of: isSelecting) {
            if !isSelecting {
                selectedItemIDs.removeAll()
            }
        }
        .confirmationDialog(
            "Delete \(selectedItemIDs.count) item\(selectedItemIDs.count == 1 ? "" : "s")? This also removes their price history.",
            isPresented: $showingDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete \(selectedItemIDs.count) Item\(selectedItemIDs.count == 1 ? "" : "s")", role: .destructive) {
                deleteSelected()
            }
        }
        .sheet(isPresented: $showingAddItem) {
            AddPriceSheet(item: nil)
        }
    }

    // MARK: Header

    private var header: some View {
        VStack(alignment: .leading, spacing: AppSpacing.m) {
            if !allCategories.isEmpty || hasUncategorized {
                categoryFilterRow
            }
            Text(countText)
                .font(AppFont.caption())
                .foregroundStyle(Color.textMuted)
                .padding(.horizontal, AppSpacing.l)
        }
    }

    private var categoryFilterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.s) {
                filterChip("All", isSelected: selectedCategory == nil) { selectedCategory = nil }
                ForEach(allCategories, id: \.self) { category in
                    filterChip(category, isSelected: selectedCategory == category) { selectedCategory = category }
                }
                if hasUncategorized {
                    filterChip("Uncategorized", isSelected: selectedCategory == "") { selectedCategory = "" }
                }
            }
            .padding(.horizontal, AppSpacing.l)
        }
    }

    private func filterChip(_ title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button {
            withAnimation(.snappy(duration: 0.2)) { action() }
        } label: {
            Chip(text: title, style: isSelected ? .selected : .neutral)
        }
        .buttonStyle(.plain)
    }

    // MARK: Rows

    @ViewBuilder
    private func row(for item: GroceryItem) -> some View {
        Group {
            if isSelecting {
                Button {
                    toggleSelection(item)
                } label: {
                    HStack(spacing: AppSpacing.m) {
                        Image(systemName: selectedItemIDs.contains(item.id) ? "checkmark.circle.fill" : "circle")
                            .font(.title3)
                            .foregroundStyle(selectedItemIDs.contains(item.id) ? Color.accent : Color.textMuted)
                        ItemRow(item: item)
                    }
                }
                .buttonStyle(.plain)
            } else {
                ZStack {
                    ItemRow(item: item)
                    // A hidden link keeps the row tappable without the system disclosure chevron.
                    NavigationLink(value: item) { EmptyView() }
                        .opacity(0)
                }
            }
        }
        .listRowBackground(Color.clear)
        .listRowSeparatorTint(Color.borderCard)
        .listRowInsets(EdgeInsets(top: AppSpacing.m, leading: AppSpacing.l, bottom: AppSpacing.m, trailing: AppSpacing.l))
        .alignmentGuide(.listRowSeparatorLeading) { _ in
            dynamicTypeSize.isAccessibilitySize ? AppSpacing.l : AppSpacing.l + 52 + AppSpacing.m
        }
        .swipeActions(edge: .leading) {
            if !isSelecting {
                Button {
                    item.isFavorite.toggle()
                } label: {
                    Label(item.isFavorite ? "Unfavorite" : "Favorite",
                          systemImage: item.isFavorite ? "star.slash" : "star")
                }
                .tint(Color.accent)
            }
        }
        .swipeActions(edge: .trailing) {
            if !isSelecting {
                Button(role: .destructive) {
                    modelContext.delete(item)
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
        .contextMenu {
            if !isSelecting {
                Button {
                    item.isFavorite.toggle()
                } label: {
                    Label(item.isFavorite ? "Remove from Favorites" : "Add to Favorites",
                          systemImage: item.isFavorite ? "star.slash" : "star")
                }
                Button(role: .destructive) {
                    modelContext.delete(item)
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
    }

    private func toggleSelection(_ item: GroceryItem) {
        if selectedItemIDs.contains(item.id) {
            selectedItemIDs.remove(item.id)
        } else {
            selectedItemIDs.insert(item.id)
        }
    }

    private func deleteSelected() {
        for item in items where selectedItemIDs.contains(item.id) {
            modelContext.delete(item)
        }
        selectedItemIDs.removeAll()
        isSelecting = false
    }
}
