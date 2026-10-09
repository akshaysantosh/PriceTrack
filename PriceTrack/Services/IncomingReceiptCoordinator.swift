import PhotosUI
import SwiftUI
import UIKit

/// The single place a receipt enters the app — whether it was scanned with the camera, picked
/// from Photos or Files, or handed over via "Open In" (wired through `onOpenURL` in
/// `PriceTrackApp`). Every source runs the same Smart Scan → on-device OCR pipeline and then
/// presents the same review screens, so a receipt gets identical treatment however it arrives.
///
/// It also owns the presentation flags for the camera / photo picker / file importer, so the
/// floating Scan button on any tab can start a scan; `RootTabView` attaches the presenters.
@MainActor
final class IncomingReceiptCoordinator: ObservableObject {
    @Published var isPresentingReview = false
    @Published var errorMessage: String?
    /// True while a receipt is being read (shows a "Reading receipt…" overlay).
    @Published var isProcessing = false

    @Published var showingCamera = false
    @Published var showingPhotoPicker = false
    @Published var showingFileImporter = false
    @Published var photoSelection: PhotosPickerItem?

    private(set) var image: UIImage?
    private(set) var smartResult: ClaudeReceiptParser.ParseResult?
    private(set) var ocrLines: [String]?
    /// Set when Smart Scan failed and the on-device reader was used instead; shown on the review screen.
    private(set) var notice: String?

    var cameraAvailable: Bool {
        UIImagePickerController.isSourceTypeAvailable(.camera)
    }

    func ingest(url: URL) {
        let accessed = url.startAccessingSecurityScopedResource()
        defer { if accessed { url.stopAccessingSecurityScopedResource() } }

        do {
            ingest(image: try ReceiptFileLoader.loadImage(from: url))
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func ingest(image: UIImage) {
        self.image = image
        isProcessing = true
        Task { await process(image) }
    }

    func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .failure(let error):
            errorMessage = error.localizedDescription
        case .success(let urls):
            if let url = urls.first { ingest(url: url) }
        }
    }

    func handlePhotoSelection() {
        guard let item = photoSelection else { return }
        photoSelection = nil
        Task {
            if let data = try? await item.loadTransferable(type: Data.self), let image = UIImage(data: data) {
                ingest(image: image)
            }
        }
    }

    private func process(_ image: UIImage) async {
        defer { isProcessing = false }
        notice = nil
        let hasSmartScan = !(KeychainStore.load() ?? "").isEmpty
        if hasSmartScan {
            do {
                smartResult = try await ClaudeReceiptParser.parse(image: image)
                isPresentingReview = true
                return
            } catch {
                notice = "Smart Scan couldn't read this receipt (\(error.localizedDescription)). Falling back to on-device text recognition."
            }
        }
        ocrLines = await TextRecognizer.recognizeLines(in: image)
        isPresentingReview = true
    }

    /// Clears state once the review sheet is dismissed (save or cancel) so a stale image/result
    /// doesn't linger for the next receipt.
    func reset() {
        isPresentingReview = false
        image = nil
        smartResult = nil
        ocrLines = nil
        notice = nil
    }
}
