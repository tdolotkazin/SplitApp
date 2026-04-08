import Foundation

struct GetBalancesEndpoint: Endpoint {
    let eventId: UUID
    var path: String { "/api/events/\(eventId.uuidString)/balances" }
    let method: HTTPMethod = .GET
}
