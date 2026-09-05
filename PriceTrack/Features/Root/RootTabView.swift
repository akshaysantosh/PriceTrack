import SwiftUI

struct RootTabView: View {
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
    }
}
