import Foundation

final class TokenStore {

    static let shared = TokenStore()

    private init() {}

    var accessToken: String?
}
