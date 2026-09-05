import SwiftUI

/// A soft, tinted button — accent as a light wash + border, not a solid fill.
/// The design system reserves accent for numbers/labels/links, "not for large fills",
/// so primary actions use this instead of a solid-filled button.
struct PrimaryButtonStyle: ButtonStyle {
    var color: Color = .accent

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(color)
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity)
            .background(color.opacity(configuration.isPressed ? 0.2 : 0.12))
            .overlay(
                RoundedRectangle(cornerRadius: AppMetrics.statRadius)
                    .stroke(color.opacity(0.35), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: AppMetrics.statRadius))
    }
}

extension ButtonStyle where Self == PrimaryButtonStyle {
    static var primary: PrimaryButtonStyle { PrimaryButtonStyle() }
    static func primary(_ color: Color) -> PrimaryButtonStyle { PrimaryButtonStyle(color: color) }
}
