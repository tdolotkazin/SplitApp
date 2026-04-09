import Foundation

final class TokenStore {
    static let shared = TokenStore()

    private init() {}

    var accessToken: String?
    var expirationDate: Date?

    var isValid: Bool {
        guard let expiration = expirationDate else { return false }
        return Date() < expiration
    }

    func save(token: String, validFor seconds: TimeInterval = 15 * 60) {
        accessToken = token
        expirationDate = Date().addingTimeInterval(seconds)
    }

    func clear() {
        accessToken = nil
        expirationDate = nil
    }
}
