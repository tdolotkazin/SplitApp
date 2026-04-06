import Foundation
import YandexLoginSDK

final class AuthObserver: YandexLoginSDKObserver {

    func didFinishLogin(with result: Result<LoginResult, Error>) {
        switch result {
        case .success(let data):
            print("TOKEN:", data.token)
            print("JWT:", data.jwt)
        case .failure(let error):
            print("ERROR:", error)
        }
    }
}
