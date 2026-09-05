import SwiftUI

struct Chip: View {
    let text: String
    var style: Style = .neutral

    enum Style {
        case neutral
        case alt
        case success
    }

    private var background: Color {
        switch style {
        case .neutral: return .chipBg
        case .alt: return .chipAltBg
        case .success: return .accentSuccess.opacity(0.14)
        }
    }

    private var foreground: Color {
        switch style {
        case .neutral: return .chipText
        case .alt: return .chipAltText
        case .success: return .accentSuccess
        }
    }

    var body: some View {
        Text(text)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(foreground)
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .background(Capsule().fill(background))
    }
}
