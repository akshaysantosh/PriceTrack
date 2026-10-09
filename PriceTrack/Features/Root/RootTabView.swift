import SwiftUI
import UniformTypeIdentifiers

struct RootTabView: View {
    @EnvironmentObject private var scanner: IncomingReceiptCoordinator

    var body: some View {
        TabView {
            NavigationStack {
                DashboardView()
            }
            .tabItem { Label("Favorites", systemImage: "star.fill") }

            NavigationStack {
                AllItemsView()
            }
            .tabItem { Label("All Items", systemImage: "list.bullet") }

            NavigationStack {
                ReceiptsView()
            }
            .tabItem { Label("Receipts", systemImage: "receipt") }
        }
        .tint(Color.accent)
        .overlay {
            if scanner.isProcessing {
                ZStack {
                    Color.black.opacity(0.25).ignoresSafeArea()
                    HStack(spacing: AppSpacing.m) {
                        ProgressView()
                        Text("Reading receipt…")
                            .font(AppFont.secondaryDetail())
                            .foregroundStyle(Color.ink)
                    }
                    .padding(AppSpacing.l)
                    .background(Color.bgCard, in: RoundedRectangle(cornerRadius: AppRadius.card))
                }
            }
        }
        // Each presenter hangs off its own anchor so they never compete for the same view.
        .background(
            Color.clear.photosPicker(isPresented: $scanner.showingPhotoPicker, selection: $scanner.photoSelection, matching: .images)
        )
        .background(
            Color.clear.fileImporter(
                isPresented: $scanner.showingFileImporter,
                allowedContentTypes: [.pdf, .image],
                allowsMultipleSelection: false
            ) { result in
                scanner.handleFileImport(result)
            }
        )
        .background(
            Color.clear.fullScreenCover(isPresented: $scanner.showingCamera) {
                DocumentCameraView(
                    onScan: { image in
                        scanner.showingCamera = false
                        scanner.ingest(image: image)
                    },
                    onCancel: { scanner.showingCamera = false }
                )
                .ignoresSafeArea()
            }
        )
        .onChange(of: scanner.photoSelection) { scanner.handlePhotoSelection() }
        .fullScreenCover(
            isPresented: $scanner.isPresentingReview,
            onDismiss: { scanner.reset() }
        ) {
            if let image = scanner.image {
                NavigationStack {
                    Group {
                        if let smartResult = scanner.smartResult {
                            SmartReceiptReviewView(image: image, parsedItems: smartResult.items, storeGuess: smartResult.storeGuess)
                        } else {
                            ReceiptReviewView(image: image, lines: scanner.ocrLines ?? [], notice: scanner.notice)
                        }
                    }
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") { scanner.reset() }
                        }
                    }
                }
            }
        }
        .alert(
            "Couldn't Open Receipt",
            isPresented: Binding(
                get: { scanner.errorMessage != nil },
                set: { isPresented in if !isPresented { scanner.errorMessage = nil } }
            ),
            presenting: scanner.errorMessage
        ) { _ in
            Button("OK") { scanner.errorMessage = nil }
        } message: { message in
            Text(message)
        }
    }
}
