import SwiftUI

/// Akshay's personal design system: warm cream/terracotta palette, card-based layout.
/// Light-mode only by design (the source system is `color-scheme: light`) — see PriceTrackApp.
extension Color {
    static let ink = Color(hex: "#1a1815")
    static let bodyText = Color(hex: "#2b2926")
    static let textSecondary = Color(hex: "#6b6862")
    static let textMuted = Color(hex: "#8f8b84")
    static let textFaint = Color(hex: "#96918a")
    static let bgPage = Color(hex: "#f7f6f3")
    static let bgCard = Color(hex: "#ffffff")
    static let borderCard = Color(hex: "#e5e2da")
    static let accent = Color(hex: "#b5541f")
    static let accentSuccess = Color(hex: "#4a7a4a")
    static let chipBg = Color(hex: "#ede9e1")
    static let chipText = Color(hex: "#45423d")
    static let chipAltBg = Color(hex: "#fbe8d9")
    static let chipAltText = Color(hex: "#8a4a15")
    static let calloutInfoBg = Color(hex: "#fdf8e8")
    static let calloutInfoBorder = Color(hex: "#e8dca0")
    static let calloutInfoText = Color(hex: "#7d6c34")
    static let calloutWarnBg = Color(hex: "#fdf0ea")
    static let calloutWarnBorder = Color(hex: "#f0c1a0")
    static let calloutWarnText = Color(hex: "#9a4a1f")

    /// Chart-only extension colors (not part of the base token set), chosen to sit
    /// comfortably alongside the warm palette for stores that aren't accent/success.
    static let chartBlue = Color(hex: "#4a6b8a")
    static let chartPurple = Color(hex: "#7a5a8a")
    static let chartOlive = Color(hex: "#6b7a4a")
    static let chartGold = Color(hex: "#a8823a")
    static let chartMaroon = Color(hex: "#8a4a4a")
}

enum AppFont {
    static func pageTitle() -> Font { .system(size: 25, weight: .heavy) }
    static func sectionLabel() -> Font { .system(size: 13, weight: .bold) }
    static func cardHeadline() -> Font { .system(size: 17, weight: .bold) }
    static func heroNumber(_ size: CGFloat = 25) -> Font { .system(size: size, weight: .heavy) }
    static func body() -> Font { .system(size: 14) }
    static func secondaryDetail() -> Font { .system(size: 13.5) }
    static func caption() -> Font { .system(size: 12) }
}

enum AppMetrics {
    static let cardRadius: CGFloat = 16
    static let statRadius: CGFloat = 14
    static let cardPadding: CGFloat = 16
    static let cardSpacing: CGFloat = 16
}

/// Per-store accent color for charts/comparison rows. Neutral chip styling is still used
/// for the primary UI so four brand colors don't clash with the warm palette; this is only
/// used where a series needs to be visually distinguished, e.g. the price history chart.
extension Store {
    var chartColor: Color {
        switch self {
        case .aldi: return .accent
        case .coles: return .accentSuccess
        case .woolworths: return .chartBlue
        case .costco: return .chartPurple
        case .vegetableMarket: return .chartOlive
        case .meatMarket: return .chartMaroon
        case .asianStore: return .chartGold
        }
    }
}

/// GroceryItem.category is free text (not a fixed enum), so its accent color is a stable hash
/// into the same chart palette rather than a switch — same category always lands on the same
/// color, with no color list to keep in sync as new categories get typed in.
extension GroceryItem {
    var categoryColor: Color {
        let palette: [Color] = [.accent, .accentSuccess, .chartBlue, .chartPurple, .chartOlive, .chartMaroon, .chartGold]
        let trimmed = category.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return .textMuted }
        let hash = trimmed.lowercased().unicodeScalars.reduce(0) { ($0 &* 31) &+ Int($1.value) }
        return palette[abs(hash) % palette.count]
    }
}
