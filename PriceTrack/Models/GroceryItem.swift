import Foundation
import SwiftData

@Model
final class GroceryItem {
    var id: UUID = UUID()
    var name: String = ""
    var category: String = ""
    var isFavorite: Bool = false
    var createdAt: Date = Date()

    @Relationship(deleteRule: .cascade, inverse: \PriceEntry.item)
    var priceEntries: [PriceEntry]? = []

    init(name: String, category: String = "", isFavorite: Bool = false) {
        self.id = UUID()
        self.name = name
        self.category = category
        self.isFavorite = isFavorite
        self.createdAt = Date()
        self.priceEntries = []
    }
}
