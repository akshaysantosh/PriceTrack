import SwiftUI

/// Handles a receipt image/PDF handed to PriceTrack via "Open In" (Files, Mail — wired up
/// through `onOpenURL` in `PriceTrackApp`), running it through the same Smart Scan → on-device
/// OCR pipeline `ScanReceiptView.handleCaptured` uses for an in-app scan, then presenting the
/// same review screens so an opened file gets identical treatment to one scanned by hand.
@MainActor
final class IncomingReceiptCoordinator: ObservableObject {
    @Published var isPresentingReview = false
    @Published var errorMessage: String?

    private(set) var image: UIImage?
    private(set) var smartResult: ClaudeReceiptParser.ParseResult?
    private(set) var ocrLines: [String]?

    func ingest(url: URL) {
        let accessed = url.startAccessingSecurityScopedResource()
        defer { if accessed { url.stopAccessingSecurityScopedResource() } }

        do {
            let loaded = try ReceiptFileLoader.loadImage(from: url)
            image = loaded
            Task { await process(loaded) }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func process(_ image: UIImage) async {
        let hasSmartScan = !(KeychainStore.load() ?? "").isEmpty
        if hasSmartScan, let result = try? await ClaudeReceiptParser.parse(image: image) {
            smartResult = result
            isPresentingReview = true
            return
        }
        ocrLines = await TextRecognizer.recognizeLines(in: image)
        isPresentingReview = true
    }

    /// Clears state once the review sheet is dismissed (save or cancel) so a stale image/result
    /// doesn't linger for the next file opened.
    func reset() {
        isPresentingReview = false
        image = nil
        smartResult = nil
        ocrLines = nil
    }
}
