import UIKit

protocol YandexAuthProvider {
    func login(from vc: UIViewController) async throws -> UserSessionToken
}
