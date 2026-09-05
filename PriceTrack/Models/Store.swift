import Foundation

enum Store: String, Codable, CaseIterable, Identifiable {
    case aldi
    case coles
    case woolworths
    case costco
    case vegetableMarket
    case meatMarket
    case asianStore

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .aldi: return "Aldi"
        case .coles: return "Coles"
        case .woolworths: return "Woolworths"
        case .costco: return "Costco"
        case .vegetableMarket: return "Vegetable Market"
        case .meatMarket: return "Meat Market"
        case .asianStore: return "Asian Store"
        }
    }
}
