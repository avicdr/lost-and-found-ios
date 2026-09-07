import Foundation
import Security

struct PrivateVerificationPayload: Codable, Sendable {
    var identifyingDetails: String
    var question: String
    var acceptedAnswers: [String]
}

/// Sensitive verification material stays in the device Keychain, outside public SwiftData rows.
enum PrivateVerificationStore {
    private static let service = "com.sahaay.private-verification"

    static func save(_ payload: PrivateVerificationPayload, for reportID: UUID) throws {
        let data = try JSONEncoder().encode(payload)
        let account = reportID.uuidString
        SecItemDelete(query(account: account))
        let result = SecItemAdd([
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ] as CFDictionary, nil)
        guard result == errSecSuccess else { throw PrivateStoreError.unableToSave(result) }
    }

    static func load(for reportID: UUID) throws -> PrivateVerificationPayload? {
        var item: CFTypeRef?
        let result = SecItemCopyMatching(query(account: reportID.uuidString, returnData: true), &item)
        if result == errSecItemNotFound { return nil }
        guard result == errSecSuccess, let data = item as? Data else { throw PrivateStoreError.unableToLoad(result) }
        return try JSONDecoder().decode(PrivateVerificationPayload.self, from: data)
    }

    static func delete(for reportID: UUID) { SecItemDelete(query(account: reportID.uuidString)) }

    private static func query(account: String, returnData: Bool = false) -> CFDictionary {
        [kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: service,
         kSecAttrAccount as String: account, kSecReturnData as String: returnData] as CFDictionary
    }
}

enum PrivateStoreError: LocalizedError {
    case unableToSave(OSStatus), unableToLoad(OSStatus)
    var errorDescription: String? { "Private verification details could not be accessed on this device." }
}
