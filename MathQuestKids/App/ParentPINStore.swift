import Foundation
import CryptoKit
import Security

protocol ParentPINStoring {
    var isConfigured: Bool { get }
    func verify(pin: String) -> Bool
    func save(pin: String) throws
    func clear() throws
}

enum ParentPINPolicy {
    static let requiredLength = 4

    static func sanitize(_ candidate: String) -> String {
        String(candidate.filter(\.isNumber).prefix(requiredLength))
    }

    static func isValid(_ candidate: String) -> Bool {
        sanitize(candidate) == candidate && candidate.count == requiredLength
    }
}

enum ParentPINStoreError: Error {
    case invalidPIN
    case unexpectedStatus(OSStatus)
}

final class KeychainParentPINStore: ParentPINStoring {
    private let service: String
    private let account = "parent-pin"

    init(service: String = Bundle.main.bundleIdentifier ?? "com.nitishprasad.sproutmath") {
        self.service = service + ".parent-pin"
    }

    var isConfigured: Bool {
        loadHash() != nil
    }

    func verify(pin: String) -> Bool {
        guard ParentPINPolicy.isValid(pin), let storedHash = loadHash() else {
            return false
        }
        return storedHash == Self.hash(for: pin)
    }

    func save(pin: String) throws {
        guard ParentPINPolicy.isValid(pin) else {
            throw ParentPINStoreError.invalidPIN
        }
        let hash = Self.hash(for: pin)
        let query = baseQuery()

        if loadHash() != nil {
            let status = SecItemUpdate(query as CFDictionary, [kSecValueData as String: hash] as CFDictionary)
            guard status == errSecSuccess else {
                throw ParentPINStoreError.unexpectedStatus(status)
            }
        } else {
            var attributes = query
            attributes[kSecValueData as String] = hash
            attributes[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
            let status = SecItemAdd(attributes as CFDictionary, nil)
            guard status == errSecSuccess else {
                throw ParentPINStoreError.unexpectedStatus(status)
            }
        }
    }

    func clear() throws {
        let status = SecItemDelete(baseQuery() as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw ParentPINStoreError.unexpectedStatus(status)
        }
    }

    private func loadHash() -> Data? {
        var query = baseQuery()
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        switch status {
        case errSecSuccess:
            return item as? Data
        case errSecItemNotFound:
            return nil
        default:
            return nil
        }
    }

    private func baseQuery() -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
    }

    private static func hash(for pin: String) -> Data {
        Data(SHA256.hash(data: Data(pin.utf8)))
    }
}

final class InMemoryParentPINStore: ParentPINStoring {
    private var storedHash: Data?

    init(initialPIN: String? = nil) {
        if let initialPIN, ParentPINPolicy.isValid(initialPIN) {
            storedHash = Self.hash(for: initialPIN)
        }
    }

    var isConfigured: Bool {
        storedHash != nil
    }

    func verify(pin: String) -> Bool {
        guard ParentPINPolicy.isValid(pin) else {
            return false
        }
        return storedHash == Self.hash(for: pin)
    }

    func save(pin: String) throws {
        guard ParentPINPolicy.isValid(pin) else {
            throw ParentPINStoreError.invalidPIN
        }
        storedHash = Self.hash(for: pin)
    }

    func clear() throws {
        storedHash = nil
    }

    private static func hash(for pin: String) -> Data {
        Data(SHA256.hash(data: Data(pin.utf8)))
    }
}
