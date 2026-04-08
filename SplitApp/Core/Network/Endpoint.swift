import Foundation

enum HTTPMethod: String {
    case GET
    case POST
    case PATCH
    case DELETE
}

protocol Endpoint {
    var path: String { get }
    var method: HTTPMethod { get }
    var queryItems: [URLQueryItem]? { get }
}

extension Endpoint {
    var queryItems: [URLQueryItem]? {
        nil
    }
}

struct AuthUserEndpoint: Endpoint {
    let path = "/api/login"
    let method: HTTPMethod = .POST
    let yandexToken: String
}

struct RefreshTokenEndpoint: Endpoint {
    let refreshToken: String
    let path = "/api/refresh"
    let method: HTTPMethod = .POST
}
