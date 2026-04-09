import Foundation

struct CreatePaymentEndpoint: Endpoint {
    let eventId: UUID
    var path: String {
        "/api/events/\(eventId.uuidString)/payments"
    }

    let method: HTTPMethod = .POST
}

struct ListPaymentsEndpoint: Endpoint {
    let eventId: UUID
    var path: String {
        "/api/events/\(eventId.uuidString)/payments"
    }

    let method: HTTPMethod = .GET
}

struct UpdatePaymentEndpoint: Endpoint {
    let id: UUID
    var path: String {
        "/api/payments/\(id.uuidString)"
    }

    let method: HTTPMethod = .PATCH
}
