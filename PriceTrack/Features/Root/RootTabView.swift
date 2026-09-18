import SwiftUI

struct RootTabView: View {
    @EnvironmentObject private var incomingReceipt: IncomingReceiptCoordinator

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

            NavigationStack {
                ScanReceiptView()
            }
            .tabItem { Label("Scan", systemImage: "camera.fill") }

            NavigationStack {
                SettingsView()
            }
            .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .tint(Color.accent)
        .fullScreenCover(
            isPresented: $incomingReceipt.isPresentingReview,
            onDismiss: { incomingReceipt.reset() }
        ) {
            if let image = incomingReceipt.image {
                NavigationStack {
                    Group {
                        if let smartResult = incomingReceipt.smartResult {
                            SmartReceiptReviewView(image: image, parsedItems: smartResult.items, storeGuess: smartResult.storeGuess)
                        } else {
                            ReceiptReviewView(image: image, lines: incomingReceipt.ocrLines ?? [])
                        }
                    }
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") { incomingReceipt.reset() }
                        }
                    }
                }
            }
        }
        .alert(
            "Couldn't Open Receipt",
            isPresented: Binding(
                get: { incomingReceipt.errorMessage != nil },
                set: { isPresented in if !isPresented { incomingReceipt.errorMessage = nil } }
            ),
            presenting: incomingReceipt.errorMessage
        ) { _ in
            Button("OK") { incomingReceipt.errorMessage = nil }
        } message: { message in
            Text(message)
        }
    }
}
