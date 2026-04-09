import UIKit

protocol YandexAuthProvider {
    func login(from viewContollerProvider: UIViewController) async throws -> UserSessionToken
}
