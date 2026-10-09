import SwiftUI

/// A flat, calm row: a neutral tile, the item name, one muted meta line, and the cheapest unit
/// price as the single highlighted element. Used by All Items and Favorites.
struct ItemRow: View {
    let item: GroceryItem
    /// On Favorites, the meta line compares against the next-cheapest store instead of showing the category.
    var showsComparison = false

    private var comparisons: [StoreComparison] {
        PriceNormalizer.latestUnitPricesByStore(for: item)
    }

    private var tileLetter: String {
        let trimmed = item.category.trimmingCharacters(in: .whitespaces)
        return trimmed.first.map { String($0).uppercased() } ?? "•"
    }

    private var tileSymbol: String? {
        CategoryClassifier.symbolName(forCategory: item.category)
    }

    private var metaText: String? {
        if showsComparison, comparisons.count > 1, let next = comparisons.dropFirst().first {
            return "Next: \(next.store.displayName) \(next.unitPrice.value.currencyString)"
        }
        return item.category.isEmpty ? nil : item.category
    }

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        if dynamicTypeSize.isAccessibilitySize {
            // Large text: stack everything so the name and price each get the full width.
            VStack(alignment: .leading, spacing: AppSpacing.s) {
                nameBlock
                priceBlock(alignment: .leading)
            }
        } else {
            HStack(spacing: AppSpacing.m) {
                tile
                nameBlock
                Spacer(minLength: AppSpacing.s)
                priceBlock(alignment: .trailing)
            }
        }
    }

    private var nameBlock: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text(item.name)
                .font(AppFont.rowTitle())
                .foregroundStyle(Color.ink)
                .lineLimit(dynamicTypeSize.isAccessibilitySize ? 4 : 2)
            if (item.isFavorite && !showsComparison) || metaText != nil {
                HStack(spacing: AppSpacing.xs) {
                    if item.isFavorite && !showsComparison {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundStyle(Color.accent)
                    }
                    if let metaText {
                        Text(metaText).lineLimit(dynamicTypeSize.isAccessibilitySize ? 3 : 1)
                    }
                }
                .font(AppFont.caption())
                .foregroundStyle(Color.textSecondary)
            }
        }
    }

    @ViewBuilder
    private func priceBlock(alignment: HorizontalAlignment) -> some View {
        if let cheapest = comparisons.first {
            VStack(alignment: alignment, spacing: AppSpacing.xs) {
                Text("\(cheapest.unitPrice.value.currencyString)/\(cheapest.unitPrice.unitLabel)")
                    .font(AppFont.price())
                    .foregroundStyle(Color.accentSuccess)
                Text(cheapest.store.displayName)
                    .font(AppFont.caption())
                    .foregroundStyle(Color.textMuted)
                    .lineLimit(2)
            }
        } else {
            Text("No prices")
                .font(AppFont.caption())
                .foregroundStyle(Color.textMuted)
        }
    }

    private var tile: some View {
        RoundedRectangle(cornerRadius: AppRadius.thumb)
            .fill(Color.chipBg)
            .frame(width: 52, height: 52)
            .overlay(
                Group {
                    if let tileSymbol {
                        Image(systemName: tileSymbol)
                    } else {
                        Text(tileLetter)
                    }
                }
                .font(.title3.weight(.medium))
                .foregroundStyle(Color.textMuted)
                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
            )
    }
}
