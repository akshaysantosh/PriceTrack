import SwiftUI
import UIKit

struct ScanReceiptView: View {
    @State private var showingCamera = false
    @State private var capturedImage: UIImage?
    @State private var recognizedLines: [String] = []
    @State private var isRecognizing = false
    @State private var showingReview = false

    @State private var smartResult: ClaudeReceiptParser.ParseResult?
    @State private var showingSmartReview = false
    @State private var smartParseErrorMessage: String?

    private var cameraAvailable: Bool {
        UIImagePickerController.isSourceTypeAvailable(.camera)
    }

    private var hasSmartScan: Bool {
        !(KeychainStore.load() ?? "").isEmpty
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppMetrics.cardSpacing) {
                PageHeader(title: "Scan")

                CardView {
                    Text("Scan a Receipt")
                        .font(AppFont.cardHeadline())
                        .foregroundStyle(Color.ink)
                    if hasSmartScan {
                        Text("Smart scan is on — Claude reads the items, prices, and quantities for you; you just confirm what to save.")
                            .font(AppFont.secondaryDetail())
                            .foregroundStyle(Color.textSecondary)
                    } else {
                        Text("Capture a receipt and tap each line to log it against an item, store, and price. Turn on Smart Scan in Settings to have items read automatically.")
                            .font(AppFont.secondaryDetail())
                            .foregroundStyle(Color.textSecondary)
                    }
                }

                VStack(spacing: 12) {
                    if cameraAvailable {
                        Button {
                            showingCamera = true
                        } label: {
                            Label("Scan with Camera", systemImage: "camera.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.primary)
                    } else {
                        CalloutBanner(text: "No camera available on this device — use \"Choose Photo\" below instead.")
                    }

                    PhotoPickerFallback { image in
                        handleCaptured(image)
                    }
                    .buttonStyle(.primary)

                    FilePickerFallback { image in
                        handleCaptured(image)
                    }
                    .buttonStyle(.primary)
                }

                if isRecognizing {
                    HStack(spacing: 8) {
                        ProgressView()
                        Text("Reading receipt…")
                            .font(AppFont.secondaryDetail())
                            .foregroundStyle(Color.textSecondary)
                    }
                }
            }
            .padding(16)
        }
        .background(Color.bgPage)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $showingCamera) {
            DocumentCameraView(
                onScan: { image in
                    showingCamera = false
                    handleCaptured(image)
                },
                onCancel: { showingCamera = false }
            )
            .ignoresSafeArea()
        }
        .navigationDestination(isPresented: $showingReview) {
            if let capturedImage {
                ReceiptReviewView(image: capturedImage, lines: recognizedLines)
            }
        }
        .navigationDestination(isPresented: $showingSmartReview) {
            if let smartResult, let capturedImage {
                SmartReceiptReviewView(image: capturedImage, parsedItems: smartResult.items, storeGuess: smartResult.storeGuess)
            }
        }
        .alert("Smart Scan Failed", isPresented: .constant(smartParseErrorMessage != nil), presenting: smartParseErrorMessage) { _ in
            Button("OK") { smartParseErrorMessage = nil }
        } message: { message in
            Text("\(message)\n\nFalling back to manual line-by-line scanning for this receipt.")
        }
    }

    private func handleCaptured(_ image: UIImage) {
        capturedImage = image
        isRecognizing = true

        guard hasSmartScan else {
            recognizeOnDevice(image)
            return
        }

        Task {
            do {
                let result = try await ClaudeReceiptParser.parse(image: image)
                await MainActor.run {
                    smartResult = result
                    isRecognizing = false
                    showingSmartReview = true
                }
            } catch {
                await MainActor.run {
                    smartParseErrorMessage = error.localizedDescription
                }
                recognizeOnDevice(image)
            }
        }
    }

    private func recognizeOnDevice(_ image: UIImage) {
        isRecognizing = true
        Task {
            let lines = await TextRecognizer.recognizeLines(in: image)
            await MainActor.run {
                recognizedLines = lines
                isRecognizing = false
                showingReview = true
            }
        }
    }
}
