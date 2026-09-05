import Foundation

enum UnitFamily {
    case volume
    case weight
    case count
}

enum UnitType: String, Codable, CaseIterable, Identifiable {
    case millilitre
    case litre
    case gram
    case kilogram
    case each
    case dozen

    var id: String { rawValue }

    var family: UnitFamily {
        switch self {
        case .millilitre, .litre: return .volume
        case .gram, .kilogram: return .weight
        case .each, .dozen: return .count
        }
    }

    /// Units that share a family with this one, in a sensible picker order.
    static func options(for family: UnitFamily) -> [UnitType] {
        allCases.filter { $0.family == family }
    }

    /// How many of this unit make up one base unit for its family
    /// (base units: litre for volume, kilogram for weight, each for count).
    private var unitsPerBase: Double {
        switch self {
        case .litre, .kilogram, .each: return 1
        case .millilitre: return 1000
        case .gram: return 1000
        case .dozen: return 1.0 / 12.0
        }
    }

    /// Converts a quantity expressed in this unit into the base unit for its family.
    func toBaseQuantity(_ quantity: Double) -> Double {
        quantity / unitsPerBase
    }

    var baseUnitLabel: String {
        switch family {
        case .volume: return "L"
        case .weight: return "kg"
        case .count: return "each"
        }
    }

    var shortLabel: String {
        switch self {
        case .millilitre: return "mL"
        case .litre: return "L"
        case .gram: return "g"
        case .kilogram: return "kg"
        case .each: return "each"
        case .dozen: return "dozen"
        }
    }
}
