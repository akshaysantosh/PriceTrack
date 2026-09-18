import SwiftUI
import UniformTypeIdentifiers

/// Lets the user pick a PDF or image file from Files (including iCloud Drive) as a receipt
/// source — handy for e-receipts saved as PDFs or screenshots kept outside Photos.
struct FilePickerFallback: View {
    var onPick: (UIImage) -> Void

    @State private var showingPicker = false
    @State private var errorMessage: String?

    var body: some View {
        Button {
            showingPicker = true
        } label: {
            Label("Choose File", systemImage: "folder.fill")
                .frame(maxWidth: .infinity)
        }
        .fileImporter(
            isPresented: $showingPicker,
            allowedContentTypes: [.pdf, .image],
            allowsMultipleSelection: false
        ) { result in
            handleResult(result)
        }
        .alert("Couldn't Open File", isPresented: .constant(errorMessage != nil), presenting: errorMessage) { _ in
            Button("OK") { errorMessage = nil }
        } message: { message in
            Text(message)
        }
    }

    private func handleResult(_ result: Result<[URL], Error>) {
        switch result {
        case .failure(let error):
            errorMessage = error.localizedDescription
        case .success(let urls):
            guard let url = urls.first else { return }
            loadImage(from: url)
        }
    }

    private func loadImage(from url: URL) {
        let accessed = url.startAccessingSecurityScopedResource()
        defer { if accessed { url.stopAccessingSecurityScopedResource() } }

        do {
            onPick(try ReceiptFileLoader.loadImage(from: url))
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
