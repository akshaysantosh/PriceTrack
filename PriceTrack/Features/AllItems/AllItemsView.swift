import SwiftUI
import SwiftData

struct AllItemsView: View {
    @Environment(\.modelContext) private var modelContext
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

    private var allSelected: Bool {
        !filteredItems.isEmpty && selectedItemIDs.count == filteredItems.count
    }

    private var emptyMessage: String {
        if items.isEmpty {
            return "No items yet. Scan a receipt or add one manually to get started."
        }
        if !searchText.isEmpty {
            return "No items match \"\(searchText)\"."
        }
        if let selectedCategory {
            return selectedCategory.isEmpty ? "No uncategorized items." : "No items in \(selectedCategory) yet."
        }
        return "No items yet."
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            PageHeader(title: "All Items")
                .overlay(alignment: .trailing) {
                    Text("\(filteredItems.count) item\(filteredItems.count == 1 ? "" : "s")")
                        .font(AppFont.caption())
                        .foregroundStyle(Color.textFaint)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 4)

            if !allCategories.isEmpty || hasUncategorized {
                categoryFilterRow
                    .padding(.top, 4)
                    .padding(.bottom, 8)
            }

            Group {
                if filteredItems.isEmpty {
                    EmptyStateView(
                        symbolName: items.isEmpty ? "cart.badge.plus" : "magnifyingglass",
                        message: emptyMessage
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                } else {
                    List {
                        ForEach(filteredItems) { item in
                            row(for: item)
                                .listRowBackground(Color.bgCard)
                                .swipeActions(edge: .leading) {
                                    if !isSelecting {
                                        Button {
                                            item.isFavorite.toggle()
                                        } label: {
                                            Label(
                                                item.isFavorite ? "Unfavorite" : "Favorite",
                                                systemImage: item.isFavorite ? "star.slash.fill" : "star.fill"
                                            )
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
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
        }
        .background(Color.bgPage)
        .searchable(text: $searchText, prompt: "Search items")
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: GroceryItem.self) { item in
            ItemDetailView(item: item)
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                if isSelecting {
                    Button(allSelected ? "Deselect All" : "Select All") {
                        selectedItemIDs = allSelected ? [] : Set(filteredItems.map(\.id))
                    }
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                if !isSelecting {
                    Button {
                        showingAddItem = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                // .bottomBar renders behind this OS's floating tab bar, so the destructive
                // delete action lives up here instead, next to Select/Done.
                if isSelecting {
                    Button(role: .destructive) {
                        showingDeleteConfirm = true
                    } label: {
                        Text(selectedItemIDs.isEmpty ? "Delete" : "Delete (\(selectedItemIDs.count))")
                    }
                    .disabled(selectedItemIDs.isEmpty)
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                if !items.isEmpty {
                    Button(isSelecting ? "Done" : "Select") {
                        isSelecting.toggle()
                    }
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

    @ViewBuilder
    private func row(for item: GroceryItem) -> some View {
        if isSelecting {
            Button {
                toggleSelection(item)
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: selectedItemIDs.contains(item.id) ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 20))
                        .foregroundStyle(selectedItemIDs.contains(item.id) ? Color.accent : Color.textMuted)
                    ItemRow(item: item)
                }
            }
            .buttonStyle(.plain)
        } else {
            NavigationLink(value: item) {
                ItemRow(item: item)
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

    private var categoryFilterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterChip(title: "All", isSelected: selectedCategory == nil) {
                    selectedCategory = nil
                }
                ForEach(allCategories, id: \.self) { category in
                    filterChip(title: category, isSelected: selectedCategory == category) {
                        selectedCategory = category
                    }
                }
                if hasUncategorized {
                    filterChip(title: "Uncategorized", isSelected: selectedCategory == "") {
                        selectedCategory = ""
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private func filterChip(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(isSelected ? Color.bgCard : Color.chipText)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Capsule().fill(isSelected ? Color.accent : Color.chipBg))
        }
        .buttonStyle(.plain)
    }
}

private struct EmptyStateView: View {
    let symbolName: String
    let message: String

    var body: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.chipBg)
                    .frame(width: 72, height: 72)
                Image(systemName: symbolName)
                    .font(.system(size: 26, weight: .medium))
                    .foregroundStyle(Color.accent)
            }
            Text(message)
                .font(AppFont.secondaryDetail())
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .padding(.top, 48)
    }
}
