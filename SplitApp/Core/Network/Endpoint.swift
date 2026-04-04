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
    var queryItems: [URLQueryItem]? { nil }
}

// MARK: - Users
struct CreateUserEndpoint: Endpoint {
    let path = "/api/users"
    let method: HTTPMethod = .POST
}

// MARK: - Events
struct CreateEventEndpoint: Endpoint {
    let path = "/api/events"
    let method: HTTPMethod = .POST
}

struct ListEventsEndpoint: Endpoint {
    let userId: UUID?
    let path = "/api/events"
    let method: HTTPMethod = .GET

    var queryItems: [URLQueryItem]? {
        guard let userId else { return nil }
        return [URLQueryItem(name: "user_id", value: userId.uuidString)]
    }
}

struct GetEventEndpoint: Endpoint {
    let id: UUID
    var path: String { "/api/events/\(id.uuidString)" }
    let method: HTTPMethod = .GET
}

struct UpdateEventEndpoint: Endpoint {
    let id: UUID
    var path: String { "/api/events/\(id.uuidString)" }
    let method: HTTPMethod = .PATCH
}

struct AddParticipantsEndpoint: Endpoint {
    let eventId: UUID
    var path: String { "/api/events/\(eventId.uuidString)/participants" }
    let method: HTTPMethod = .POST
}

struct RemoveParticipantEndpoint: Endpoint {
    let eventId: UUID
    let userId: UUID
    var path: String { "/api/events/\(eventId.uuidString)/participants/\(userId.uuidString)" }
    let method: HTTPMethod = .DELETE
}

// MARK: - Receipts
struct CreateReceiptEndpoint: Endpoint {
    let eventId: UUID
    var path: String { "/api/events/\(eventId.uuidString)/receipts" }
    let method: HTTPMethod = .POST
}

struct ListReceiptsEndpoint: Endpoint {
    let eventId: UUID
    var path: String { "/api/events/\(eventId.uuidString)/receipts" }
    let method: HTTPMethod = .GET
}

struct UpdateReceiptEndpoint: Endpoint {
    let id: UUID
    var path: String { "/api/receipts/\(id.uuidString)" }
    let method: HTTPMethod = .PATCH
}

struct DeleteReceiptEndpoint: Endpoint {
    let id: UUID
    var path: String { "/api/receipts/\(id.uuidString)" }
    let method: HTTPMethod = .DELETE
}

// MARK: - Balances
struct GetBalancesEndpoint: Endpoint {
    let eventId: UUID
    var path: String { "/api/events/\(eventId.uuidString)/balances" }
    let method: HTTPMethod = .GET
}

// MARK: - Payments
struct CreatePaymentEndpoint: Endpoint {
    let eventId: UUID
    var path: String { "/api/events/\(eventId.uuidString)/payments" }
    let method: HTTPMethod = .POST
}

struct ListPaymentsEndpoint: Endpoint {
    let eventId: UUID
    var path: String { "/api/events/\(eventId.uuidString)/payments" }
    let method: HTTPMethod = .GET
}

struct UpdatePaymentEndpoint: Endpoint {
    let id: UUID
    var path: String { "/api/payments/\(id.uuidString)" }
    let method: HTTPMethod = .PATCH
}
