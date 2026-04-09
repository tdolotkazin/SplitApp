import Foundation
import KeychainSwift

final class KeychainStorage: SecureStorage {
    private let keychain = KeychainSwift()

    func save(_ value: String, for key: String) {
        keychain.set(value, forKey: key)
    }

    func get(_ key: String) -> String? {
        keychain.get(key)
    }

    func delete(_ key: String) {
        keychain.delete(key)
    }
}
