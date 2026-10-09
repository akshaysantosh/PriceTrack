import SwiftUI

/// Akshay's personal design system: warm cream/terracotta palette, calm and editorial.
/// Light-mode only by design (the source system is `color-scheme: light`) — see PriceTrackApp.
/// Matches Stash's theme (text styles for Dynamic Type, spacing/radius scales, a darker muted
/// text colour); PriceTrack adds the chart colours and price fonts below.
///
/// Accent rule: terracotta is for the one primary action on a screen, the selected state, and
/// links — not for decoration. Green (`accentSuccess`) means "cheapest".
extension Color {
    static let ink = Color(hex: "#1a1815")
    static let bodyText = Color(hex: "#2b2926")
    static let textSecondary = Color(hex: "#6b6862")
    /// Metadata and hints. Darkened from the old #8f8b84 so small text stays readable on cream.
    static let textMuted = Color(hex: "#7a766f")
    static let bgPage = Color(hex: "#f8f6f1")
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

/// Built on text styles so everything scales with Dynamic Type.
enum AppFont {
    static func detailTitle() -> Font { .title2.weight(.bold) }
    static func cardHeadline() -> Font { .headline.weight(.bold) }
    static func rowTitle() -> Font { .callout.weight(.semibold) }
    static func sectionLabel() -> Font { .caption.weight(.semibold) }
    static func button() -> Font { .callout.weight(.semibold) }
    static func chip() -> Font { .footnote.weight(.semibold) }
    static func body() -> Font { .subheadline }
    static func secondaryDetail() -> Font { .footnote }
    static func caption() -> Font { .caption }
    /// A unit price inside a row (the one highlighted number).
    static func price() -> Font { .callout.weight(.bold) }
    /// The big cheapest-price figure on a detail screen.
    static func heroPrice() -> Font { .largeTitle.weight(.bold) }
}

enum AppSpacing {
    static let xs: CGFloat = 4
    static let s: CGFloat = 8
    static let m: CGFloat = 12
    static let l: CGFloat = 16
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
}

enum AppRadius {
    static let thumb: CGFloat = 14
    static let button: CGFloat = 14
    static let card: CGFloat = 16
    static let banner: CGFloat = 12
}

enum AppMetrics {
    static let cardRadius = AppRadius.card
    static let cardPadding = AppSpacing.l
    static let cardSpacing = AppSpacing.l
}

/// Per-store accent color for charts. Neutral chip styling is used for the primary UI so brand
/// colors don't clash with the warm palette; this is only used where a series needs to be
/// visually distinguished, e.g. the price history chart.
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
