import Foundation

extension APIClient {

    /// POST /api/events
    func createEvent(_ request: CreateEventRequest) async throws -> EventDTO {
        try await self.request(endpoint: .createEvent, body: request)
    }

    /// GET /api/events?user_id=...
    func listEvents(userId: UUID? = nil) async throws -> [EventDTO] {
        try await request(endpoint: .listEvents(userId: userId))
    }

    /// GET /api/events/{id}
    func getEvent(id: UUID) async throws -> EventDTO {
        try await request(endpoint: .getEvent(id: id))
    }

    /// PATCH /api/events/{id}
    func updateEvent(id: UUID, _ request: UpdateEventRequest) async throws -> EventDTO {
        try await self.request(endpoint: .updateEvent(id: id), body: request)
    }

    /// POST /api/events/{id}/participants
    func addParticipants(eventId: UUID, _ request: AddParticipantsRequest) async throws -> [UserDTO] {
        try await self.request(endpoint: .addParticipants(eventId: eventId), body: request)
    }

    /// DELETE /api/events/{id}/participants/{user_id}
    func removeParticipant(eventId: UUID, userId: UUID) async throws {
        try await requestVoid(endpoint: .removeParticipant(eventId: eventId, userId: userId))
    }
}
