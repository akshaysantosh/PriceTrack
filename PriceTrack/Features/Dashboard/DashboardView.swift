import SwiftUI
import SwiftData

struct DashboardView: View {
    @Query(filter: #Predicate<GroceryItem> { $0.isFavorite }, sort: \GroceryItem.name)
    private var favorites: [GroceryItem]
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        List {
            if favorites.isEmpty {
                EmptyStateView(
                    symbolName: "star",
                    message: "No favorites yet. Swipe an item in All Items and tap the star to track its cheapest store here."
                )
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            } else {
                ForEach(favorites) { item in
                    ZStack {
                        ItemRow(item: item, showsComparison: true)
                        NavigationLink(value: item) { EmptyView() }
                            .opacity(0)
                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparatorTint(Color.borderCard)
                    .listRowSeparator(.hidden, edges: .top)
                    .listRowInsets(EdgeInsets(top: AppSpacing.m, leading: AppSpacing.l, bottom: AppSpacing.m, trailing: AppSpacing.l))
                    .alignmentGuide(.listRowSeparatorLeading) { _ in
                        dynamicTypeSize.isAccessibilitySize ? AppSpacing.l : AppSpacing.l + 52 + AppSpacing.m
                    }
                    .swipeActions(edge: .trailing) {
                        Button {
                            item.isFavorite = false
                        } label: {
                            Label("Unfavorite", systemImage: "star.slash")
                        }
                        .tint(Color.accent)
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(PaperBackground())
        .navigationTitle("Favorites")
        .navigationBarTitleDisplayMode(.large)
        .navigationDestination(for: GroceryItem.self) { item in
            ItemDetailView(item: item)
        }
        .settingsSheet()
    }
}
