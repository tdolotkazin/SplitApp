import Foundation

struct CreateEventEndpoint: Endpoint {
    let path = "/api/events"
    let method: HTTPMethod = .POST
}

struct ListEventsEndpoint: Endpoint {
    let path = "/api/events"
    let method: HTTPMethod = .GET
}

struct GetEventEndpoint: Endpoint {
    let id: UUID
    var path: String {
        "/api/events/\(id.uuidString)"
    }

    let method: HTTPMethod = .GET
}

struct UpdateEventEndpoint: Endpoint {
    let id: UUID
    var path: String {
        "/api/events/\(id.uuidString)"
    }

    let method: HTTPMethod = .PATCH
}

struct AddParticipantsEndpoint: Endpoint {
    let eventId: UUID
    var path: String {
        "/api/events/\(eventId.uuidString)/participants"
    }

    let method: HTTPMethod = .POST
}

struct DeleteEventEndpoint: Endpoint {
    let id: UUID
    var path: String {
        "/api/events/\(id.uuidString)"
    }

    let method: HTTPMethod = .DELETE
}

struct RemoveParticipantEndpoint: Endpoint {
    let eventId: UUID
    let userId: UUID
    var path: String {
        "/api/events/\(eventId.uuidString)/participants/\(userId.uuidString)"
    }

    let method: HTTPMethod = .DELETE
}
