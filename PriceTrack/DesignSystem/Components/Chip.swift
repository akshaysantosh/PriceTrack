import SwiftUI

/// The one chip/pill used across the app (tags, status, active filters).
struct Chip: View {
    let text: String
    var style: Style = .neutral
    /// Shows a small ✕, for chips that dismiss something when tapped (an active filter, a selected tag).
    var showsRemove = false

    enum Style {
        case neutral
        case selected
        case outlined
        case alt
        case success
    }

    private var background: Color {
        switch style {
        case .neutral: return .chipBg
        case .selected: return .accent
        case .outlined: return .clear
        case .alt: return .chipAltBg
        case .success: return .accentSuccess.opacity(0.14)
        }
    }

    private var foreground: Color {
        switch style {
        case .neutral: return .chipText
        case .selected: return .bgCard
        case .outlined: return .textSecondary
        case .alt: return .chipAltText
        case .success: return .accentSuccess
        }
    }

    var body: some View {
        HStack(spacing: AppSpacing.xs) {
            Text(text)
                .font(AppFont.chip())
            if showsRemove {
                Image(systemName: "xmark")
                    .font(.caption2.weight(.bold))
            }
        }
        .foregroundStyle(foreground)
        .padding(.horizontal, AppSpacing.m)
        .padding(.vertical, 5)
        .background(Capsule().fill(background))
        .overlay(Capsule().stroke(style == .outlined ? Color.borderCard : .clear, lineWidth: 1))
    }
}
