import Foundation

/// Single source of truth for grocery categories: what SF Symbol represents a category,
/// what item names suggest it (used to auto-fill a new item's category), and what synonyms
/// in a stored category string should map to that symbol. `GroceryItem.category` stays free
/// text by design, so this is a best-effort keyword match, not an enum — anything that
/// doesn't match falls back to the plain monogram avatar / no auto-fill.
enum CategoryClassifier {
    private struct Definition {
        let name: String
        let symbolName: String
        let categoryKeywords: [String]
        let itemNameKeywords: [String]
    }

    private static let definitions: [Definition] = [
        Definition(
            name: "Frozen", symbolName: "snowflake",
            categoryKeywords: ["frozen"],
            itemNameKeywords: ["frozen", "ice cream", "icecream"]
        ),
        Definition(
            name: "Produce", symbolName: "carrot.fill",
            categoryKeywords: ["produce", "fruit", "vegetable", "veg"],
            itemNameKeywords: [
                "apple", "banana", "carrot", "lettuce", "tomato", "onion", "potato", "spinach",
                "broccoli", "capsicum", "cucumber", "avocado", "mango", "berries", "berry",
                "grape", "orange", "lemon", "lime", "garlic", "mushroom", "zucchini", "pumpkin", "corn"
            ]
        ),
        Definition(
            name: "Dairy", symbolName: "drop.fill",
            categoryKeywords: ["dairy"],
            itemNameKeywords: ["milk", "cheese", "yogurt", "yoghurt", "butter", "egg"]
        ),
        Definition(
            name: "Seafood", symbolName: "fish.fill",
            categoryKeywords: ["seafood", "fish"],
            itemNameKeywords: ["fish", "salmon", "tuna", "prawn", "shrimp", "crab", "oyster"]
        ),
        Definition(
            name: "Meat", symbolName: "fork.knife",
            categoryKeywords: ["meat", "poultry"],
            itemNameKeywords: ["chicken", "beef", "pork", "lamb", "steak", "mince", "sausage", "bacon", "turkey"]
        ),
        Definition(
            name: "Deli", symbolName: "fork.knife.circle.fill",
            categoryKeywords: ["deli"],
            itemNameKeywords: ["ham", "salami", "deli"]
        ),
        Definition(
            name: "Bakery", symbolName: "birthday.cake.fill",
            categoryKeywords: ["bakery", "bread"],
            itemNameKeywords: ["bread", "bagel", "croissant", "muffin", "bun", "roll", "cake", "pastry"]
        ),
        Definition(
            name: "Beverages", symbolName: "cup.and.saucer.fill",
            categoryKeywords: ["beverage", "drink"],
            itemNameKeywords: ["juice", "soda", "water", "coffee", "tea", "cola", "cordial"]
        ),
        Definition(
            name: "Alcohol", symbolName: "wineglass.fill",
            categoryKeywords: ["alcohol", "wine", "beer", "liquor"],
            itemNameKeywords: ["wine", "beer", "vodka", "whisky", "whiskey", "rum", "gin", "cider"]
        ),
        Definition(
            name: "Pantry", symbolName: "cabinet.fill",
            categoryKeywords: ["pantry", "grocery"],
            itemNameKeywords: ["rice", "pasta", "flour", "sugar", "oil", "sauce", "canned", "cereal", "noodle", "spice"]
        ),
        Definition(
            name: "Snacks", symbolName: "popcorn.fill",
            categoryKeywords: ["snack", "candy"],
            itemNameKeywords: ["chips", "crisps", "chocolate", "candy", "popcorn", "biscuit", "cookie"]
        ),
        Definition(
            name: "Household", symbolName: "house.fill",
            categoryKeywords: ["household", "cleaning"],
            itemNameKeywords: ["detergent", "tissue", "paper towel", "toilet paper", "cleaner", "soap"]
        ),
        Definition(
            name: "Health & Beauty", symbolName: "cross.case.fill",
            categoryKeywords: ["health", "beauty", "personal care", "pharmacy"],
            itemNameKeywords: ["shampoo", "toothpaste", "vitamin", "deodorant", "sunscreen"]
        ),
        Definition(
            name: "Baby", symbolName: "teddybear.fill",
            categoryKeywords: ["baby", "infant"],
            itemNameKeywords: ["diaper", "nappy", "formula", "baby"]
        )
    ]

    /// Best-effort category guess from an item's name, for prefilling (never overwriting) the
    /// category field when a new item is created. Returns nil when nothing matches confidently.
    static func guess(for itemName: String) -> String? {
        let lowerName = itemName.lowercased()
        for definition in definitions {
            if definition.itemNameKeywords.contains(where: { lowerName.contains($0) }) {
                return definition.name
            }
        }
        return nil
    }

    /// SF Symbol for a stored category string (matched by keyword, not exact string), or nil
    /// if nothing matches — callers should fall back to a generic/monogram treatment.
    static func symbolName(forCategory category: String) -> String? {
        let lowerCategory = category.trimmingCharacters(in: .whitespaces).lowercased()
        guard !lowerCategory.isEmpty else { return nil }
        for definition in definitions {
            if definition.categoryKeywords.contains(where: { lowerCategory.contains($0) }) {
                return definition.symbolName
            }
        }
        return nil
    }
}
