import Foundation

/// Shared between the main app and the Share Extension — both need the exact same App Group
/// identifier to read/write the same SwiftData store.
enum AppGroup {
    static let identifier = "group.com.akshay.pricetrack"

    /// nil if the App Group entitlement isn't actually provisioned (e.g. a free Apple ID
    /// account that can't grant this capability) — callers should fall back to local-only
    /// storage rather than crash.
    static var containerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: identifier)
    }
}
