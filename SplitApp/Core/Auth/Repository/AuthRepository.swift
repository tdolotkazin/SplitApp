import Foundation
import UIKit

protocol AuthRepository {
    func login(provider: AuthProvider, vc: UIViewController) async throws
        -> UserSessionToken
}
