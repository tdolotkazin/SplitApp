import Foundation

protocol EventsRepository {
    func listEvents(userId: UUID?) async throws -> [Event]
    func refreshEvents(userId: UUID?) async throws -> [Event]
    func createEvent(_ command: CreateEventCommand) async throws -> Event
    func getEvent(id: UUID) async throws -> Event
    func getCachedEvent(id: UUID) async throws -> Event?
    func refreshEvent(id: UUID) async throws -> Event
    func updateEvent(id: UUID, _ command: UpdateEventCommand) async throws -> Event
    func addParticipants(eventId: UUID, _ command: AddParticipantsCommand) async throws -> [User]
    func removeParticipant(eventId: UUID, userId: UUID) async throws
}
