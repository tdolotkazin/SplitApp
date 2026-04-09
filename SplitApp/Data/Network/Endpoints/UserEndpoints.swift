import Foundation

struct ListUsersEndpoint: Endpoint {
    let path = "/api/users"
    let method: HTTPMethod = .GET
}
