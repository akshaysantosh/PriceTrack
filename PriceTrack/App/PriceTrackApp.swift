import SwiftUI
import SwiftData
import UIKit

@main
struct PriceTrackApp: App {
    /// Flip to `true` once you have a paid Apple Developer account and have restored the
    /// entitlements block in project.yml — free "Personal Team" accounts can't provision
    /// the iCloud capability at all, so this defaults to local-only. See README.md.
    static let useCloudKit = false

    let modelContainer: ModelContainer = {
        let schema = Schema([GroceryItem.self, PriceEntry.self, Receipt.self])
        let configuration = ModelConfiguration(
            schema: schema,
            cloudKitDatabase: Self.useCloudKit ? .automatic : .none
        )
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }()

    init() {
        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithOpaqueBackground()
        navAppearance.backgroundColor = UIColor(Color.bgPage)
        navAppearance.titleTextAttributes = [.foregroundColor: UIColor(Color.ink)]
        navAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor(Color.ink)]
        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance

        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithOpaqueBackground()
        tabAppearance.backgroundColor = UIColor(Color.bgCard)
        UITabBar.appearance().standardAppearance = tabAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabAppearance
    }

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .preferredColorScheme(.light)
                .tint(Color.accent)
        }
        .modelContainer(modelContainer)
    }
}
