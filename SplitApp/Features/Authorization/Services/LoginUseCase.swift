import Foundation
import UIKit

final class LoginUseCase {

    private let service: AuthService
    private let secureStorage: KeychainStorage

    init(service: AuthService, secureStorage: KeychainStorage) {
        self.service = service
        self.secureStorage = secureStorage
    }

    func execute(provider: AuthProvider, viewContollerProvider: UIViewController) async throws
        -> AuthResponse
    {

        let authResponse = try await service.login(provider: provider, viewContollerProvider: viewContollerProvider)

        TokenStore.shared.accessToken = authResponse.accessToken
        secureStorage.save(authResponse.refreshToken, for: "refresh_token")

        return authResponse

    }

    func isLoggedIn() -> Bool {
        return secureStorage.get("refresh_token") != nil
    }

}
