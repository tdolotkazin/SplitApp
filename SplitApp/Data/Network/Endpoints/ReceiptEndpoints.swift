import Foundation

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
