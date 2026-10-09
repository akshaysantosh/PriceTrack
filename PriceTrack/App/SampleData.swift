#if DEBUG
import SwiftData
import SwiftUI
import UIKit

/// Debug-only: launch with `-seedSampleData` to run against an in-memory store filled with
/// sample items, prices (across more than four stores) and receipts. Used for screenshots and
/// eyeballing layouts in the Simulator.
enum SampleData {
    static func makeContainer() -> ModelContainer {
        let schema = Schema([GroceryItem.self, PriceEntry.self, Receipt.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        let container = try! ModelContainer(for: schema, configurations: [configuration])
        let context = ModelContext(container)
        populate(context)
        try? context.save()
        return container
    }

    private static func day(_ daysAgo: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date()) ?? Date()
    }

    private static func populate(_ context: ModelContext) {
        let receiptA = Receipt(store: .woolworths, date: day(3), receiptImageData: receiptArt(.systemGreen))
        let receiptB = Receipt(store: .aldi, date: day(10), receiptImageData: receiptArt(.systemOrange))
        let receiptC = Receipt(store: .costco, date: day(21), receiptImageData: receiptArt(.systemBlue))
        [receiptA, receiptB, receiptC].forEach(context.insert)

        // (name, category, favourite, [(store, price, qty, unit, daysAgo, receipt?)])
        typealias Entry = (Store, Decimal, Double, UnitType, Int, Receipt?)
        let items: [(String, String, Bool, [Entry])] = [
            ("A2 Milk 2L", "Dairy", true, [
                (.coles, 4.60, 2, .litre, 40, nil), (.woolworths, 4.40, 2, .litre, 22, nil),
                (.aldi, 3.90, 2, .litre, 10, receiptB), (.costco, 4.10, 2, .litre, 5, nil), (.aldi, 3.75, 2, .litre, 2, nil)]),
            ("Free Range Eggs 12pk", "Dairy", true, [
                (.coles, 6.20, 12, .each, 30, nil), (.aldi, 5.40, 12, .each, 10, receiptB), (.woolworths, 5.90, 12, .each, 3, receiptA)]),
            ("Chicken Breast", "Meat", true, [
                (.meatMarket, 9.50, 1, .kilogram, 14, nil), (.woolworths, 12.00, 1, .kilogram, 3, receiptA), (.costco, 8.90, 1.5, .kilogram, 21, receiptC)]),
            ("Basmati Rice 5kg", "Pantry", false, [
                (.asianStore, 14.00, 5, .kilogram, 18, nil), (.costco, 15.50, 5, .kilogram, 21, receiptC), (.coles, 17.00, 5, .kilogram, 40, nil)]),
            ("Bananas", "Produce", true, [
                (.vegetableMarket, 2.50, 1, .kilogram, 7, nil), (.woolworths, 3.90, 1, .kilogram, 3, receiptA), (.aldi, 3.20, 1, .kilogram, 10, receiptB)]),
            ("Sourdough Loaf", "Bakery", false, [(.aldi, 4.20, 1, .each, 10, receiptB), (.woolworths, 5.50, 1, .each, 3, receiptA)]),
            ("Olive Oil 1L", "Pantry", false, [(.costco, 14.90, 1, .litre, 21, receiptC), (.coles, 11.00, 1, .litre, 33, nil)]),
            ("Greek Yoghurt 1kg", "Dairy", false, [(.aldi, 4.50, 1, .kilogram, 10, receiptB)]),
            ("Dishwasher Tablets", "", false, []),
        ]

        for (name, category, favourite, entries) in items {
            let item = GroceryItem(name: name, category: category, isFavorite: favourite)
            context.insert(item)
            for (store, price, qty, unit, ago, receipt) in entries {
                context.insert(PriceEntry(store: store, price: price, quantity: qty, unit: unit, date: day(ago), item: item, receipt: receipt))
            }
        }
    }

    private static func receiptArt(_ color: UIColor) -> Data? {
        let size = CGSize(width: 600, height: 800)
        let image = UIGraphicsImageRenderer(size: size).image { ctx in
            UIColor(white: 0.97, alpha: 1).setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
            color.withAlphaComponent(0.25).setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: size.width, height: 120))
            UIColor(white: 0.75, alpha: 1).setFill()
            for row in 0..<14 {
                ctx.fill(CGRect(x: 50, y: 170 + CGFloat(row) * 40, width: row % 3 == 0 ? 360 : 460, height: 12))
            }
        }
        return image.jpegData(compressionQuality: 0.8)
    }
}
#endif
