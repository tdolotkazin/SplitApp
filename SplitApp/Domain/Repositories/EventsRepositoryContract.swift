import Foundation

protocol EventsRepository {
    /// Online-first: network first, fallback to cache when network fails.
    func listEvents(userId: UUID?) async throws -> [Event]
    /// Forces network refresh and updates local cache.
    func refreshEvents(userId: UUID?) async throws -> [Event]
    func createEvent(_ command: CreateEventCommand) async throws -> Event
    /// Online-first for a single event.
    func getEvent(id: UUID) async throws -> Event
    /// Returns only cached value.
    func getCachedEvent(id: UUID) async throws -> Event?
    /// Forces network refresh for a single event.
    func refreshEvent(id: UUID) async throws -> Event
    func deleteEvent(id: UUID) async throws
    func updateEvent(id: UUID, _ command: UpdateEventCommand) async throws -> Event
    func addParticipants(eventId: UUID, _ command: AddParticipantsCommand) async throws -> [User]
    func removeParticipant(eventId: UUID, userId: UUID) async throws
}
