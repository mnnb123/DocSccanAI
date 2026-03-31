import Foundation
import Security

/// Secure storage for sensitive data using iOS Keychain.
final class KeychainHelper {

    // MARK: - Singleton

    static let shared = KeychainHelper()

    private init() {}

    // MARK: - Keys

    enum Key: String {
        case claudeAPIKey = "com.docscanai.claudeAPIKey"
        case openaiAPIKey = "com.docscanai.openaiAPIKey"
    }

    // MARK: - Save

    /// Save a string value to Keychain.
    @discardableResult
    func save(_ value: String, for key: Key) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }

        // Delete existing item first
        delete(key)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key.rawValue,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    // MARK: - Read

    /// Read a string value from Keychain.
    func read(_ key: Key) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key.rawValue,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let string = String(data: data, encoding: .utf8) else {
            return nil
        }

        return string
    }

    // MARK: - Delete

    /// Delete a value from Keychain.
    @discardableResult
    func delete(_ key: Key) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key.rawValue
        ]

        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }

    // MARK: - Check Existence

    /// Check if a key exists in Keychain.
    func exists(_ key: Key) -> Bool {
        read(key) != nil
    }

    // MARK: - Migration from UserDefaults

    /// Migrate API keys from UserDefaults to Keychain.
    func migrateFromUserDefaults() {
        if let claudeKey = UserDefaults.standard.string(forKey: "claudeAPIKey"),
           !claudeKey.isEmpty {
            save(claudeKey, for: .claudeAPIKey)
            UserDefaults.standard.removeObject(forKey: "claudeAPIKey")
        }

        if let openaiKey = UserDefaults.standard.string(forKey: "openaiAPIKey"),
           !openaiKey.isEmpty {
            save(openaiKey, for: .openaiAPIKey)
            UserDefaults.standard.removeObject(forKey: "openaiAPIKey")
        }
    }
}
