import SwiftUI

struct ItemComparisonCard: View {
    let item: GroceryItem

    private var comparisons: [StoreComparison] {
        PriceNormalizer.latestUnitPricesByStore(for: item)
    }

    var body: some View {
        CardView {
            HStack {
                Text(item.name)
                    .font(AppFont.cardHeadline())
                    .foregroundStyle(Color.ink)
                Spacer()
                if !item.category.isEmpty {
                    Text(item.category)
                        .font(AppFont.caption())
                        .foregroundStyle(Color.textMuted)
                }
            }

            if let cheapest = comparisons.first {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(cheapest.unitPrice.value.currencyString)
                        .font(AppFont.heroNumber())
                        .foregroundStyle(Color.accentSuccess)
                    Text("/ \(cheapest.unitPrice.unitLabel) at \(cheapest.store.displayName)")
                        .font(AppFont.secondaryDetail())
                        .foregroundStyle(Color.textSecondary)
                }
                .padding(.top, 4)

                if comparisons.count > 1 {
                    HStack(spacing: 6) {
                        ForEach(comparisons.dropFirst()) { comparison in
                            Chip(text: "\(comparison.store.displayName) \(comparison.unitPrice.value.currencyString)")
                        }
                    }
                    .padding(.top, 4)
                }
            } else {
                Text("No prices logged yet")
                    .font(AppFont.secondaryDetail())
                    .foregroundStyle(Color.textMuted)
                    .padding(.top, 4)
            }
        }
    }
}
