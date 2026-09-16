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
        let configuration: ModelConfiguration
        if let groupURL = AppGroup.containerURL {
            // Shared with the Share Extension, so receipts saved from the share sheet show up
            // here too. Existing local data predates this — migrate it in before SwiftData opens
            // the (new, otherwise-empty) store at the App Group location, or it would look lost.
            let storeURL = groupURL.appendingPathComponent("PriceTrack.sqlite")
            Self.migrateLocalStoreIfNeeded(to: storeURL)
            configuration = ModelConfiguration(
                schema: schema,
                url: storeURL,
                cloudKitDatabase: Self.useCloudKit ? .automatic : .none
            )
        } else {
            // App Group entitlement isn't actually provisioned (e.g. a free Apple ID account) —
            // fall back to the app's own local storage rather than crash. The Share Extension
            // won't be able to see this data in that case, but the main app keeps working.
            configuration = ModelConfiguration(
                schema: schema,
                cloudKitDatabase: Self.useCloudKit ? .automatic : .none
            )
        }
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }()

    /// One-time, idempotent: copies the app's pre-App-Group SwiftData store (`default.store` in
    /// Application Support, SwiftData's default location when no `url:` is given) into the App
    /// Group container, so existing receipts/items survive this update. No-ops once the App
    /// Group store already exists, and no-ops if there was never a local store to migrate
    /// (fresh installs). Runs before `ModelContainer` opens either location.
    private static func migrateLocalStoreIfNeeded(to storeURL: URL) {
        let fileManager = FileManager.default
        guard !fileManager.fileExists(atPath: storeURL.path) else { return }
        guard let appSupport = try? fileManager.url(
            for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: false
        ) else { return }
        let legacyStoreURL = appSupport.appendingPathComponent("default.store")
        guard fileManager.fileExists(atPath: legacyStoreURL.path) else { return }

        for suffix in ["", "-wal", "-shm"] {
            let source = URL(fileURLWithPath: legacyStoreURL.path + suffix)
            let destination = URL(fileURLWithPath: storeURL.path + suffix)
            guard fileManager.fileExists(atPath: source.path) else { continue }
            try? fileManager.copyItem(at: source, to: destination)
        }
    }

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
