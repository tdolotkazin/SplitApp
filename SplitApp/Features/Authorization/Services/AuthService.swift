import Foundation
import UIKit

protocol AuthService {
    func login(provider: AuthProvider, viewContollerProvider: UIViewController)
        async throws
        -> AuthResponse
}

enum AuthProvider: String, Codable {
    case yandex
    // case google
    // case apple
}
