import SwiftUI
import PDFKit
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

        if url.pathExtension.lowercased() == "pdf" {
            guard let document = PDFDocument(url: url), let page = document.page(at: 0) else {
                errorMessage = "Couldn't read that PDF — it may still be downloading from iCloud. Try again in a moment."
                return
            }
            // Render at 3x the page's point size so small receipt print stays legible for OCR.
            let pageBounds = page.bounds(for: .mediaBox)
            let scale: CGFloat = 3
            let targetSize = CGSize(width: pageBounds.width * scale, height: pageBounds.height * scale)
            let image = page.thumbnail(of: targetSize, for: .mediaBox)
            onPick(image)
        } else {
            guard let data = try? Data(contentsOf: url), let image = UIImage(data: data) else {
                errorMessage = "Couldn't read that file — it may still be downloading from iCloud. Try again in a moment."
                return
            }
            onPick(image)
        }
    }
}
