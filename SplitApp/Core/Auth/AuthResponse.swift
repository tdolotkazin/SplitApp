import Foundation

struct AuthResponse: Decodable {
    let user: User
    let accessToken: String
    let refreshToken: String

    enum CodingKeys: String, CodingKey {
            case user
            case accessToken = "access_token"
            case refreshToken = "refresh_token"
        }
}

struct AuthResponseRefreshToken: Decodable {
    let accessToken: String
    let refreshToken: String
}
