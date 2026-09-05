import SwiftUI
import SwiftData

/// Search-or-create picker for a GroceryItem, shared by manual price entry and
/// receipt line assignment so both flows create/match items the same way.
struct ItemPicker: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \GroceryItem.name) private var allItems: [GroceryItem]
    @Binding var selectedItem: GroceryItem?
    @State private var searchText: String = ""

    private var matches: [GroceryItem] {
        guard !searchText.isEmpty else { return allItems }
        return allItems.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    private var exactMatchExists: Bool {
        allItems.contains { $0.name.localizedCaseInsensitiveCompare(searchText) == .orderedSame }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField("Item name (e.g. A2 Milk 2L)", text: $searchText)
                .onChange(of: searchText) { selectedItem = nil }

            if let selectedItem {
                Chip(text: "Selected: \(selectedItem.name)", style: .success)
            } else if !searchText.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(matches.prefix(5)) { item in
                        Button {
                            selectedItem = item
                            searchText = item.name
                        } label: {
                            Text(item.name)
                                .font(AppFont.body())
                                .foregroundStyle(Color.ink)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }

                    if !exactMatchExists {
                        Button {
                            let newItem = GroceryItem(name: searchText, category: CategoryClassifier.guess(for: searchText) ?? "")
                            modelContext.insert(newItem)
                            selectedItem = newItem
                        } label: {
                            Label("Create \"\(searchText)\"", systemImage: "plus.circle.fill")
                                .font(AppFont.body())
                                .foregroundStyle(Color.accent)
                        }
                    }
                }
            }
        }
    }
}
