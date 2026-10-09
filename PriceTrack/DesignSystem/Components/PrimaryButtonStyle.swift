import SwiftUI

/// A soft, tinted button — accent as a light wash + border, not a solid fill — for secondary
/// actions. The one primary action per screen uses `SolidAccentButtonStyle` below.
struct PrimaryButtonStyle: ButtonStyle {
    var color: Color = .accent

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppFont.button())
            .foregroundStyle(color)
            .padding(.vertical, AppSpacing.m)
            .padding(.horizontal, AppSpacing.l)
            .frame(maxWidth: .infinity)
            .background(color.opacity(configuration.isPressed ? 0.2 : 0.12))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.button)
                    .stroke(color.opacity(0.35), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.button))
    }
}

extension ButtonStyle where Self == PrimaryButtonStyle {
    static var primary: PrimaryButtonStyle { PrimaryButtonStyle() }
    static func primary(_ color: Color) -> PrimaryButtonStyle { PrimaryButtonStyle(color: color) }
}

/// The single solid-accent call to action on a screen (e.g. "Open" on the detail screen).
struct SolidAccentButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppFont.button())
            .foregroundStyle(Color.bgCard)
            .padding(.vertical, AppSpacing.m + 2)
            .padding(.horizontal, AppSpacing.l)
            .frame(maxWidth: .infinity)
            .background(Color.accent.opacity(configuration.isPressed ? 0.85 : (isEnabled ? 1 : 0.4)))
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.button))
    }
}

extension ButtonStyle where Self == SolidAccentButtonStyle {
    static var solidAccent: SolidAccentButtonStyle { SolidAccentButtonStyle() }
}
