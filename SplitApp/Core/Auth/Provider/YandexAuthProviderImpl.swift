import Foundation
import UIKit
import YandexLoginSDK

enum AuthError: Error {
    case invalidToken
}
final class YandexAuthProviderImpl: YandexAuthProvider {
    private var continuation: CheckedContinuation<UserSessionToken, Error>?
    private let vcProvider: ViewControllerProvider

    init(vcProvider: ViewControllerProvider) {
        self.vcProvider = vcProvider
        YandexLoginSDK.shared.add(observer: self)
    }

    deinit {
        YandexLoginSDK.shared.remove(observer: self)
    }

    func login(from viewContollerProvider: UIViewController) async throws -> UserSessionToken {
        guard let viewContollerProvider = vcProvider.rootViewController else {
            throw AuthError.invalidToken
        }

        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation

            do {
                try YandexLoginSDK.shared.authorize(with: viewContollerProvider)
            } catch {
                self.continuation?.resume(throwing: error)
                self.continuation = nil
            }
        }

    }
}

extension YandexAuthProviderImpl: YandexLoginSDKObserver {
    func didFinishLogin(with result: Result<LoginResult, any Error>) {
        switch result {

        case .success(let data):
            let authToken = UserSessionToken(
                jwt: data.jwt,
                token: data.token,

            )
            continuation?.resume(returning: authToken)

        case .failure(let error):
            print("Ошибка входа: \(error.localizedDescription)")
        }
    }
}

/*
 return try await withCheckedThrowingContinuation { continuation in self.continuation = continuation

 do {
 try YandexLoginSDK.shared.authorize(with: vc)
 } catch {
 continuation.resume(throwing: error)
 self.continuation = nil
 }
 }*/
