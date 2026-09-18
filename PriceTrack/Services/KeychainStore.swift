import Foundation
import Security

/// Minimal Keychain wrapper for the Anthropic API key — stored securely on-device only,
/// never in source code, UserDefaults, or iCloud.
///
/// Uses a shared `kSecAttrAccessGroup` (the same one declared in both targets' entitlements)
/// so the Share Extension can read the same key the main app saved and run Smart Scan itself,
/// instead of always falling back to on-device OCR.
enum KeychainStore {
    private static let service = "com.akshay.pricetrack.apikey"
    private static let account = "anthropic-api-key"
    /// `$(AppIdentifierPrefix)` only gets substituted by Xcode inside `.entitlements` files at
    /// build time — it is NOT resolved in a Swift string literal, so the actual team ID has to
    /// be spelled out here to match. Confirmed directly from a signed build's own entitlements
    /// (`codesign -d --entitlements`) rather than assumed from a certificate's display name —
    /// those aren't always the same string (an earlier version of this file used the
    /// certificate's own identifier, "NKRNBPGT9Y", which silently did not match the actual
    /// application-identifier team prefix, "K5NNTQSVGX", and caused every Keychain read/write
    /// to fail with errSecMissingEntitlement). If the signing team ever changes, re-verify with
    /// `codesign -d --entitlements -` on a fresh build rather than trusting the cert name.
    private static let accessGroup = "K5NNTQSVGX.com.akshay.pricetrack.shared"

    private static var baseQuery: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecAttrAccessGroup as String: accessGroup
        ]
    }

    /// Returns the real `OSStatus` from `SecItemAdd` rather than swallowing it — a caller that
    /// ignores this return value has no way to know a write silently failed (e.g. a Keychain
    /// entitlement mismatch) versus actually succeeded, which is exactly how "Saved to this
    /// device's Keychain" could show even though nothing was actually persisted.
    @discardableResult
    static func save(_ value: String) -> OSStatus {
        let data = Data(value.utf8)
        SecItemDelete(baseQuery as CFDictionary)

        var attributes = baseQuery
        attributes[kSecValueData as String] = data
        attributes[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        return SecItemAdd(attributes as CFDictionary, nil)
    }

    static func load() -> String? {
        var query = baseQuery
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func delete() {
        SecItemDelete(baseQuery as CFDictionary)
    }
}
