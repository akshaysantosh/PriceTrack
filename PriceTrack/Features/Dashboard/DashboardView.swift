import SwiftUI
import SwiftData

struct DashboardView: View {
    @Query(filter: #Predicate<GroceryItem> { $0.isFavorite }, sort: \GroceryItem.name)
    private var favorites: [GroceryItem]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppMetrics.cardSpacing) {
                PageHeader(title: "Favorites")

                if favorites.isEmpty {
                    CalloutBanner(text: "No favorites yet. Star an item from All Items to track its price across stores here.")
                } else {
                    ForEach(favorites) { item in
                        NavigationLink(value: item) {
                            ItemComparisonCard(item: item)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(16)
        }
        .background(Color.bgPage)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: GroceryItem.self) { item in
            ItemDetailView(item: item)
        }
    }
}
