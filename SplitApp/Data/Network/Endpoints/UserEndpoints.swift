import Foundation

struct CreateUserEndpoint: Endpoint {
    let path = "/api/users"
    let method: HTTPMethod = .POST
}
