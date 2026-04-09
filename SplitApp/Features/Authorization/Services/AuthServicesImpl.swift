import Foundation
import KeychainSwift
import UIKit

final class AuthServicesImpl: AuthService {
    private let repository: AuthRepository
    private let serviceBackend: AuthServiceBackend
    private let secureStorage: KeychainStorage

    init(
        repository: AuthRepository,
        serviceBackend: AuthServiceBackend,
        secureStorage _: KeychainStorage
    ) {
        self.repository = repository
        self.serviceBackend = serviceBackend
        secureStorage = KeychainStorage()
    }

    func login(provider: AuthProvider, viewContollerProvider: UIViewController)
        async throws
        -> AuthResponse
    {
        let token = try await repository.login(
            provider: provider,
            viewContollerProvider: viewContollerProvider
        )
        return try await serviceBackend.sendTokenToBackend(token: token.token)
    }
}
