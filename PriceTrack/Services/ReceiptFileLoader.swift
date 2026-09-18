import UIKit
import PDFKit

/// Loads a receipt image or PDF (rendering its first page) from a file URL — shared by
/// `FilePickerFallback`'s file picker and `IncomingReceiptCoordinator`'s "Open In PriceTrack"
/// handling, so the PDF-rendering logic exists in exactly one place.
enum ReceiptFileLoader {
    struct LoadError: LocalizedError {
        var errorDescription: String? {
            "Couldn't read that file — it may still be downloading from iCloud. Try again in a moment."
        }
    }

    static func loadImage(from url: URL) throws -> UIImage {
        if url.pathExtension.lowercased() == "pdf" {
            guard let document = PDFDocument(url: url), let page = document.page(at: 0) else {
                throw LoadError()
            }
            // Render at 3x the page's point size so small receipt print stays legible for OCR.
            let pageBounds = page.bounds(for: .mediaBox)
            let scale: CGFloat = 3
            let targetSize = CGSize(width: pageBounds.width * scale, height: pageBounds.height * scale)
            return page.thumbnail(of: targetSize, for: .mediaBox)
        }
        guard let data = try? Data(contentsOf: url), let image = UIImage(data: data) else {
            throw LoadError()
        }
        return image
    }
}
