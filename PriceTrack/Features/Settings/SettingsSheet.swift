import SwiftUI

/// Adds the gear button (leading toolbar slot) and the Smart Scan settings sheet to a screen.
/// Settings used to be a whole tab for one API-key field; now it's one tap away on every tab.
private struct SettingsSheetModifier: ViewModifier {
    @State private var showingSettings = false

    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .foregroundStyle(Color.ink)
                    }
                    .accessibilityLabel("Smart Scan settings")
                }
            }
            .sheet(isPresented: $showingSettings) {
                NavigationStack { SettingsView() }
                    .presentationDetents([.medium, .large])
            }
    }
}

extension View {
    func settingsSheet() -> some View {
        modifier(SettingsSheetModifier())
    }
}
