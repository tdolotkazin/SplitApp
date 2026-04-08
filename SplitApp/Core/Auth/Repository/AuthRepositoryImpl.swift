import Foundation
import UIKit

final class AuthRepositoryImpl: AuthRepository {

    private let yandex: YandexAuthProvider

    init(
        yandex: YandexAuthProvider,
    ) {
        self.yandex = yandex
    }

    func login(provider: AuthProvider, viewContollerProvider: UIViewController) async throws
        -> UserSessionToken
    {
        switch provider {
        case .yandex:
            return try await yandex.login(from: viewContollerProvider)
        }
    }
}
