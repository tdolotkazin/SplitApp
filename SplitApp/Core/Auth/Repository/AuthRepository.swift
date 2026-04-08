import Foundation
import UIKit

protocol AuthRepository {
    func login(provider: AuthProvider, viewContollerProvider: UIViewController) async throws
        -> UserSessionToken
}
