import SwiftUI

/// A small quiet label above a block of content ("About", "Note"). No rule, no top padding —
/// the parent stack decides spacing.
struct SectionLabel: View {
    let text: String

    var body: some View {
        Text(text.uppercased())
            .font(AppFont.sectionLabel())
            .tracking(0.6)
            .foregroundStyle(Color.textMuted)
    }
}
