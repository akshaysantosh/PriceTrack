import SwiftUI

/// The one solid-accent control on the list screens: a floating "add" button. Floating surfaces
/// get a soft shadow for elevation, per the design system.
struct FloatingAddButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.title2.weight(.semibold))
                .foregroundStyle(Color.bgCard)
                .frame(width: 58, height: 58)
                .background(Circle().fill(Color.accent))
                .shadow(color: .black.opacity(0.18), radius: 10, y: 4)
        }
        .accessibilityLabel("Add link")
    }
}
