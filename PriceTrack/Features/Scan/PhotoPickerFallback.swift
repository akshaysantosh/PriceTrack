import SwiftUI
import PhotosUI
import UIKit

/// Photo-library alternative to the camera scanner — always available (including in Simulator,
/// which has no camera), and handy if a receipt was already photographed elsewhere.
struct PhotoPickerFallback: View {
    var onPick: (UIImage) -> Void

    @State private var selection: PhotosPickerItem?

    var body: some View {
        PhotosPicker(selection: $selection, matching: .images) {
            Label("Choose Photo", systemImage: "photo.on.rectangle")
                .frame(maxWidth: .infinity)
        }
        .onChange(of: selection) { _, newItem in
            guard let newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    onPick(image)
                }
                selection = nil
            }
        }
    }
}
