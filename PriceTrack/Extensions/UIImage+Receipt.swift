import UIKit

extension UIImage {
    /// Downscales + compresses a receipt photo before storing it, so the SwiftData payload stays
    /// small while the photo remains legible as a reference.
    func compressedForReceipt() -> Data? {
        let maxWidth: CGFloat = 900
        guard size.width > 0 else { return jpegData(compressionQuality: 0.6) }
        let scale = min(1, maxWidth / size.width)
        let targetSize = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        let resized = renderer.image { _ in draw(in: CGRect(origin: .zero, size: targetSize)) }
        return resized.jpegData(compressionQuality: 0.6)
    }
}
