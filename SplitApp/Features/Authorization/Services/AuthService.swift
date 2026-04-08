import Foundation
import UIKit

protocol AuthService {
    func login(provider: AuthProvider, vc: UIViewController) async throws
        -> AuthResponse
}

enum AuthProvider: String, Codable {
    case yandex
    // case google
    //case apple
}
