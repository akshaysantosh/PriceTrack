import Foundation
import SwiftData

@Model
final class PriceEntry {
    var id: UUID = UUID()
    var storeRaw: String = Store.woolworths.rawValue
    var price: Decimal = 0
    var quantity: Double = 1
    var unitRaw: String = UnitType.each.rawValue
    var date: Date = Date()
    /// Legacy per-entry photo, kept only so entries saved before Receipt existed still show
    /// their image. New entries store the photo once on the shared Receipt instead.
    var receiptImageData: Data? = nil
    var item: GroceryItem? = nil
    var receipt: Receipt? = nil

    init(
        store: Store,
        price: Decimal,
        quantity: Double,
        unit: UnitType,
        date: Date = Date(),
        receiptImageData: Data? = nil,
        item: GroceryItem? = nil,
        receipt: Receipt? = nil
    ) {
        self.id = UUID()
        self.storeRaw = store.rawValue
        self.price = price
        self.quantity = quantity
        self.unitRaw = unit.rawValue
        self.date = date
        self.receiptImageData = receiptImageData
        self.item = item
        self.receipt = receipt
    }

    var store: Store {
        get { Store(rawValue: storeRaw) ?? .woolworths }
        set { storeRaw = newValue.rawValue }
    }

    var unit: UnitType {
        get { UnitType(rawValue: unitRaw) ?? .each }
        set { unitRaw = newValue.rawValue }
    }
}
