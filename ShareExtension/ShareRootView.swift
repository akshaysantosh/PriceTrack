import SwiftUI
import SwiftData
import PDFKit
import UniformTypeIdentifiers
import UIKit

/// Receives a shared receipt image or PDF, runs it through the same Smart Scan → on-device OCR
/// pipeline `ScanReceiptView.handleCaptured` uses in-app, then hands off to the *same* review
/// screens (`SmartReceiptReviewView` / `ReceiptReviewView`) — unmodified — so a shared receipt
/// gets identical treatment to one scanned from inside the app.
struct ShareRootView: View {
    let extensionContext: NSExtensionContext?
    let onFinish: () -> Void
    let onCancel: () -> Void

    @State private var errorMessage: String?
    @State private var sharedModelContext: ModelContext?
    @State private var loadedImage: UIImage?
    @State private var smartResult: ClaudeReceiptParser.ParseResult?
    @State private var ocrLines: [String]?
    @State private var isPresentingReview = false

    var body: some View {
        statusView
            .task { await load() }
            .sheet(isPresented: $isPresentingReview, onDismiss: {
                // The reused review views insert into the context but don't explicitly save it
                // (fine in the main app, which stays alive for SwiftData's autosave to catch up).
                // This extension's process ends right after completeRequest, so the save has to
                // happen explicitly here or a just-saved receipt could be lost.
                try? sharedModelContext?.save()
                onFinish()
            }) {
                reviewSheet
            }
    }

    @ViewBuilder
    private var statusView: some View {
        VStack(spacing: 12) {
            if let errorMessage {
                Text(errorMessage)
                    .font(AppFont.secondaryDetail())
                    .foregroundStyle(Color.textSecondary)
                    .multilineTextAlignment(.center)
                Button("Close", action: onCancel)
                    .buttonStyle(.primary)
            } else {
                ProgressView()
                Text("Reading receipt…")
                    .font(AppFont.secondaryDetail())
                    .foregroundStyle(Color.textSecondary)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.bgPage)
    }

    @ViewBuilder
    private var reviewSheet: some View {
        // Both are set together in `load()` before `isPresentingReview` can become true, so this
        // is always non-nil in practice — guarded rather than force-unwrapped regardless.
        if let loadedImage, let sharedModelContext {
            NavigationStack {
                Group {
                    if let smartResult {
                        SmartReceiptReviewView(image: loadedImage, parsedItems: smartResult.items, storeGuess: smartResult.storeGuess)
                    } else {
                        ReceiptReviewView(image: loadedImage, lines: ocrLines ?? [])
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel", action: onCancel)
                    }
                }
            }
            .environment(\.modelContext, sharedModelContext)
        }
    }

    // MARK: - Load + process

    private func load() async {
        guard let context = try? makeSharedContext() else {
            errorMessage = "Couldn't reach PriceTrack's shared storage. Open PriceTrack directly and try adding this receipt from the Scan tab instead."
            return
        }
        sharedModelContext = context

        guard let image = await extractImage() else {
            errorMessage = "Couldn't read a receipt image or PDF from this share."
            return
        }
        loadedImage = image
        await processReceipt(image)
    }

    private func processReceipt(_ image: UIImage) async {
        let hasSmartScan = !(KeychainStore.load() ?? "").isEmpty
        if hasSmartScan {
            if let result = try? await ClaudeReceiptParser.parse(image: image) {
                smartResult = result
                isPresentingReview = true
                return
            }
            // Falls through to on-device OCR, same as ScanReceiptView.handleCaptured does on error.
        }
        ocrLines = await TextRecognizer.recognizeLines(in: image)
        isPresentingReview = true
    }

    // MARK: - Shared SwiftData store

    private func makeSharedContext() throws -> ModelContext {
        guard let groupURL = AppGroup.containerURL else {
            throw CocoaError(.fileNoSuchFile)
        }
        let schema = Schema([GroceryItem.self, PriceEntry.self, Receipt.self])
        let configuration = ModelConfiguration(
            schema: schema,
            url: groupURL.appendingPathComponent("PriceTrack.sqlite"),
            cloudKitDatabase: .none
        )
        let container = try ModelContainer(for: schema, configurations: [configuration])
        return ModelContext(container)
    }

    // MARK: - NSItemProvider extraction

    private func extractImage() async -> UIImage? {
        guard let items = extensionContext?.inputItems as? [NSExtensionItem] else { return nil }

        for item in items {
            guard let attachments = item.attachments else { continue }

            for attachment in attachments where attachment.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                if let image = await loadImage(from: attachment) { return image }
            }
            for attachment in attachments where attachment.hasItemConformingToTypeIdentifier(UTType.pdf.identifier) {
                if let image = await loadPDFFirstPage(from: attachment) { return image }
            }
        }
        return nil
    }

    private func loadImage(from attachment: NSItemProvider) async -> UIImage? {
        let item: Any? = await withCheckedContinuation { continuation in
            attachment.loadItem(forTypeIdentifier: UTType.image.identifier, options: nil) { item, _ in
                continuation.resume(returning: item)
            }
        }
        if let image = item as? UIImage {
            return image
        }
        if let url = item as? URL, let data = try? Data(contentsOf: url) {
            return UIImage(data: data)
        }
        if let data = item as? Data {
            return UIImage(data: data)
        }
        return nil
    }

    /// Mirrors FilePickerFallback's PDF handling exactly (page 0, rendered at 3x scale so small
    /// receipt print stays legible for OCR) — duplicated here rather than shared cross-target,
    /// since it's a handful of lines and this extension already can't reuse a SwiftUI View file.
    private func loadPDFFirstPage(from attachment: NSItemProvider) async -> UIImage? {
        let item: Any? = await withCheckedContinuation { continuation in
            attachment.loadItem(forTypeIdentifier: UTType.pdf.identifier, options: nil) { item, _ in
                continuation.resume(returning: item)
            }
        }
        let document: PDFDocument?
        if let url = item as? URL {
            document = PDFDocument(url: url)
        } else if let data = item as? Data {
            document = PDFDocument(data: data)
        } else {
            document = nil
        }
        guard let document, let page = document.page(at: 0) else { return nil }
        let pageBounds = page.bounds(for: .mediaBox)
        let scale: CGFloat = 3
        let targetSize = CGSize(width: pageBounds.width * scale, height: pageBounds.height * scale)
        return page.thumbnail(of: targetSize, for: .mediaBox)
    }
}
