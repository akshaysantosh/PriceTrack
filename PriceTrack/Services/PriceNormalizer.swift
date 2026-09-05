import Foundation

struct UnitPrice {
    let value: Decimal
    let unitLabel: String // e.g. "L", "kg", "each"
}

struct StoreComparison: Identifiable {
    let store: Store
    let entry: PriceEntry
    let unitPrice: UnitPrice
    var id: String { store.rawValue }
}

enum PriceNormalizer {
    /// The price per base unit (per L / per kg / per each) for a given price + quantity + unit.
    static func unitPrice(price: Decimal, quantity: Double, unit: UnitType) -> UnitPrice? {
        guard quantity > 0 else { return nil }
        let baseQuantity = unit.toBaseQuantity(quantity)
        guard baseQuantity > 0 else { return nil }
        let value = price / Decimal(baseQuantity)
        return UnitPrice(value: value, unitLabel: unit.baseUnitLabel)
    }

    static func unitPrice(for entry: PriceEntry) -> UnitPrice? {
        unitPrice(price: entry.price, quantity: entry.quantity, unit: entry.unit)
    }

    /// The most recent entry per store for an item, each paired with its normalised unit price,
    /// sorted cheapest first. Entries whose unit family doesn't match the item's dominant family
    /// are excluded since they can't be fairly compared (e.g. a per-each price alongside per-kg ones).
    static func latestUnitPricesByStore(for item: GroceryItem) -> [StoreComparison] {
        let entries = item.priceEntries ?? []
        guard !entries.isEmpty else { return [] }

        let familyCounts = Dictionary(grouping: entries, by: { $0.unit.family })
        guard let dominantFamily = familyCounts.max(by: { $0.value.count < $1.value.count })?.key else {
            return []
        }

        let comparable = entries.filter { $0.unit.family == dominantFamily }
        let latestByStore = Dictionary(grouping: comparable, by: { $0.store })
            .compactMapValues { $0.max(by: { $0.date < $1.date }) }

        return latestByStore.compactMap { store, entry -> StoreComparison? in
            guard let up = unitPrice(for: entry) else { return nil }
            return StoreComparison(store: store, entry: entry, unitPrice: up)
        }.sorted { $0.unitPrice.value < $1.unitPrice.value }
    }

    static func cheapestStore(for item: GroceryItem) -> StoreComparison? {
        latestUnitPricesByStore(for: item).first
    }
}
