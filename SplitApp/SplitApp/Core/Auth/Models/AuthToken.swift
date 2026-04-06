import Foundation

struct AuthToken: Codable {
    let accessToken: String
}

struct YandexTokenResponse: Codable {
    let accessToken: String
    let expiresIn: Int
    let tokenType: String
    let refreshToken: String?
}

enum AuthState {
    case idle
    case loading
    case authenticated(AuthToken)
    case error(String)
}

enum AuthError: LocalizedError {
    case yandexSDKError(String)
    case tokenExchangeFailed(String)
    case networkError(String)
    case invalidToken
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .yandexSDKError(let message):
            return "Ошибка Яндекс SDK: \(message)"
        case .tokenExchangeFailed(let message):
            return "Ошибка обмена токена: \(message)"
        case .networkError(let message):
            return "Ошибка сети: \(message)"
        case .invalidToken:
            return "Недействительный токен"
        case .unknown:
            return "Неизвестная ошибка"
        }
    }
}
