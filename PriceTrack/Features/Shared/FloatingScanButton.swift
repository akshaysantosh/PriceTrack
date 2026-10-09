import SwiftUI

/// The floating accent button on the list screens. Tapping it opens the ways to add a receipt
/// (and, where it makes sense, to add an item by hand). Same look as Stash's `FloatingAddButton`.
struct FloatingScanButton: View {
    @EnvironmentObject private var scanner: IncomingReceiptCoordinator
    var onAddManually: (() -> Void)?

    var body: some View {
        Menu {
            if scanner.cameraAvailable {
                Button {
                    scanner.showingCamera = true
                } label: {
                    Label("Scan with Camera", systemImage: "camera")
                }
            }
            Button {
                scanner.showingPhotoPicker = true
            } label: {
                Label("Choose Photo", systemImage: "photo.on.rectangle")
            }
            Button {
                scanner.showingFileImporter = true
            } label: {
                Label("Choose File", systemImage: "folder")
            }
            if let onAddManually {
                Divider()
                Button(action: onAddManually) {
                    Label("Add item manually", systemImage: "plus")
                }
            }
        } label: {
            Image(systemName: "doc.viewfinder")
                .font(.title2.weight(.semibold))
                .foregroundStyle(Color.bgCard)
                .frame(width: 58, height: 58)
                .background(Circle().fill(Color.accent))
                .shadow(color: .black.opacity(0.18), radius: 10, y: 4)
        }
        .accessibilityLabel("Add receipt or item")
    }
}
