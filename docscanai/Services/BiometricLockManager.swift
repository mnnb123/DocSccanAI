import Foundation
import LocalAuthentication
import Security
import CryptoKit

/// Biometric lock manager using Face ID / Touch ID.
actor BiometricLockManager {

    enum BiometricError: Error, LocalizedError {
        case notAvailable
        case notEnrolled
        case lockFailed(Error)
        case unlockFailed(Error)
        case keychainError(Error)
        case documentNotFound

        var errorDescription: String? {
            switch self {
            case .notAvailable: return "Biometric authentication not available"
            case .notEnrolled: return "No biometric enrolled on this device"
            case .lockFailed(let e): return "Lock failed: \(e.localizedDescription)"
            case .unlockFailed(let e): return "Unlock failed: \(e.localizedDescription)"
            case .keychainError(let e): return "Keychain error: \(e.localizedDescription)"
            case .documentNotFound: return "Document not found in secure storage"
            }
        }
    }

    enum BiometricType {
        case faceID
        case touchID
        case none
    }

    // MARK: - Biometric Availability

    var biometricType: BiometricType {
        let context = LAContext()
        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return .none
        }

        switch context.biometryType {
        case .faceID: return .faceID
        case .touchID: return .touchID
        case .none: return .none
        @unknown default: return .none
        }
    }

    var isBiometricAvailable: Bool {
        biometricType != .none
    }

    // MARK: - App Lock

    /// Authenticate to unlock the app.
    func authenticateAppLock(reason: String = "Mở khóa DocScan AI") async throws {
        let context = LAContext()
        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            throw BiometricError.notAvailable
        }

        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )

            if !success {
                throw BiometricError.unlockFailed(NSError(domain: "BiometricLock", code: -1))
            }
        } catch let laError as LAError {
            switch laError.code {
            case .userFallback, .biometryNotAvailable:
                throw BiometricError.notAvailable
            case .biometryNotEnrolled:
                throw BiometricError.notEnrolled
            default:
                throw BiometricError.unlockFailed(laError)
            }
        }
    }

    // MARK: - Per-Document Lock (AES-256-GCM encryption)

    private var keychainService: String { "com.docscanai.secure" }

    /// Encrypt PDF data and store key in Keychain.
    func lockDocument(pdfData: Data, documentId: UUID) async throws -> Data {
        let key = SymmetricKey(size: .bits256)
        let keyData = key.withUnsafeBytes { Data($0) }

        let sealedBox = try AES.GCM.seal(pdfData, using: key)
        guard let combined = sealedBox.combined else {
            throw BiometricError.lockFailed(NSError(domain: "BiometricLock", code: -2))
        }

        try saveKeyToKeychain(keyData, for: documentId)
        return combined
    }

    /// Decrypt PDF data using key from Keychain.
    func unlockDocument(encryptedData: Data, documentId: UUID) async throws -> Data {
        guard let keyData = try loadKeyFromKeychain(for: documentId) else {
            throw BiometricError.documentNotFound
        }

        let key = SymmetricKey(data: keyData)
        let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
        return try AES.GCM.open(sealedBox, using: key)
    }

    // MARK: - Keychain Operations

    private func saveKeyToKeychain(_ keyData: Data, for documentId: UUID) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: documentId.uuidString,
            kSecValueData as String: keyData,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        SecItemDelete(query as CFDictionary)

        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw BiometricError.keychainError(NSError(domain: NSOSStatusErrorDomain, code: Int(status)))
        }
    }

    private func loadKeyFromKeychain(for documentId: UUID) throws -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: documentId.uuidString,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecItemNotFound {
            return nil
        }

        guard status == errSecSuccess else {
            throw BiometricError.keychainError(NSError(domain: NSOSStatusErrorDomain, code: Int(status)))
        }

        return result as? Data
    }

    /// Delete key for a document (permanently lock it without the key).
    func deleteKey(for documentId: UUID) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: documentId.uuidString
        ]

        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw BiometricError.keychainError(NSError(domain: NSOSStatusErrorDomain, code: Int(status)))
        }
    }
}
