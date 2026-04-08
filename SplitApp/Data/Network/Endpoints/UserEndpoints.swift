import Foundation

struct ListUsersEndpoint: Endpoint {
    let path = "/api/users"
    let method: HTTPMethod = .GET
}

struct AuthUserEndpoint: Endpoint {
    let path = "/api/login"
    let method: HTTPMethod = .POST
    let yandexToken: String
}

struct RefreshTokenEndpoint: Endpoint {
    let path = "/api/refresh"
    let method: HTTPMethod = .POST
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
