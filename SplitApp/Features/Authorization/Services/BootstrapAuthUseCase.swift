import Foundation
import KeychainSwift

final class BootstrapAuthUseCase {
    private let storage: SecureStorage

    init(storage: SecureStorage) {
        self.storage = storage
    }

    func execute() async -> Bool {
        guard storage.get("refresh_token") != nil else {
            return false
        }

        do {
            try await APIClient.shared.refreshAccessTokenIfNeeded()
            return true
        } catch {
            storage.delete("refresh_token")
            return false
        }
    }
}
