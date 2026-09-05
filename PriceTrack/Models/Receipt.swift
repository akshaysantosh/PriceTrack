import Foundation
import SwiftData

/// One scanned/imported receipt — groups the PriceEntry rows it produced so a whole shop can be
/// viewed, and undone, as a unit. Manual entries (via AddPriceSheet) have no Receipt.
@Model
final class Receipt {
    var id: UUID = UUID()
    var storeRaw: String = Store.woolworths.rawValue
    var date: Date = Date()
    var receiptImageData: Data? = nil
    var createdAt: Date = Date()

    @Relationship(deleteRule: .cascade, inverse: \PriceEntry.receipt)
    var priceEntries: [PriceEntry]? = []

    init(store: Store, date: Date, receiptImageData: Data? = nil) {
        self.id = UUID()
        self.storeRaw = store.rawValue
        self.date = date
        self.receiptImageData = receiptImageData
        self.createdAt = Date()
        self.priceEntries = []
    }

    var store: Store {
        get { Store(rawValue: storeRaw) ?? .woolworths }
        set { storeRaw = newValue.rawValue }
    }
}
