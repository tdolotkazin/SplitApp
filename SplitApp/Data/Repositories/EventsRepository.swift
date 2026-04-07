import Foundation
import CoreData

protocol EventsRepositoryProtocol {
    func listEvents(userId: UUID?) async throws -> [Event]
    func createEvent(_ request: CreateEventRequest) async throws -> Event
    func getEvent(id: UUID) async throws -> Event
    func updateEvent(id: UUID, _ request: UpdateEventRequest) async throws -> Event
    func addParticipants(eventId: UUID, _ request: AddParticipantsRequest) async throws -> [User]
    func removeParticipant(eventId: UUID, userId: UUID) async throws
}

final class EventsRepository: EventsRepositoryProtocol {
    private let apiClient: APIClient
    private let coreDataStore: CoreDataStore

    init(apiClient: APIClient = .shared, coreDataStore: CoreDataStore = .shared) {
        self.apiClient = apiClient
        self.coreDataStore = coreDataStore
    }

    // MARK: - Networking + Database Operations

    func createEvent(_ request: CreateEventRequest) async throws -> Event {
        let dto: EventDTO = try await apiClient.request(endpoint: CreateEventEndpoint(), body: request)
        try await coreDataStore.performBackground { [weak self] context in
            try self?.upsertEvent(dto, in: context)
        }
        return EventMapper.mapToDomain(dto: dto)
    }

    func listEvents(userId: UUID? = nil) async throws -> [Event] {
        do {
            let dtos: [EventDTO] = try await apiClient.request(endpoint: ListEventsEndpoint(userId: userId))

            try await coreDataStore.performBackground { [weak self] context in
                try self?.upsertEvents(dtos, in: context)
            }

            return dtos.map(EventMapper.mapToDomain)
        } catch {
            let cachedEvents: [Event] = try await coreDataStore.performBackground { context in
                let fetchRequest: NSFetchRequest<CDEvent> = CDEvent.fetchRequest()
                fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \CDEvent.createdAt, ascending: false)]
                let cdEvents = try context.fetch(fetchRequest)
                return cdEvents.compactMap(EventMapper.mapToDomain)
            }

            if cachedEvents.isEmpty {
                throw error
            }

            return cachedEvents
        }
    }

    func getEvent(id: UUID) async throws -> Event {
        let dto: EventDTO = try await apiClient.request(endpoint: GetEventEndpoint(id: id))
        try await coreDataStore.performBackground { [weak self] context in
            try self?.upsertEvent(dto, in: context)
        }
        return EventMapper.mapToDomain(dto: dto)
    }

    func updateEvent(id: UUID, _ request: UpdateEventRequest) async throws -> Event {
        let dto: EventDTO = try await apiClient.request(endpoint: UpdateEventEndpoint(id: id), body: request)
        try await coreDataStore.performBackground { [weak self] context in
            try self?.upsertEvent(dto, in: context)
        }
        return EventMapper.mapToDomain(dto: dto)
    }

    func addParticipants(eventId: UUID, _ request: AddParticipantsRequest) async throws -> [User] {
        let dtos: [UserDTO] = try await apiClient.request(
            endpoint: AddParticipantsEndpoint(eventId: eventId),
            body: request
        )
        return dtos.map(UserMapper.mapToDomain)
    }

    func removeParticipant(eventId: UUID, userId: UUID) async throws {
        try await apiClient.requestVoid(endpoint: RemoveParticipantEndpoint(eventId: eventId, userId: userId))
    }

    // MARK: - Core Data Internal Methods (Extracted from CoreDataStore+Events)

    private func upsertEvent(_ dto: EventDTO, in context: NSManagedObjectContext) throws {
        let fetchRequest: NSFetchRequest<CDEvent> = CDEvent.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", dto.id as CVarArg)
        fetchRequest.fetchLimit = 1

        let existing = try context.fetch(fetchRequest).first
        let event = existing ?? CDEvent(context: context)
        event.update(from: dto)

        let participantFetch: NSFetchRequest<CDUser> = CDUser.fetchRequest()
        participantFetch.predicate = NSPredicate(format: "id IN %@", dto.users)
        let participants = try context.fetch(participantFetch)
        event.participants = NSSet(array: participants)
    }

    private func upsertEvents(_ dtos: [EventDTO], in context: NSManagedObjectContext) throws {
        for dto in dtos {
            try upsertEvent(dto, in: context)
        }
    }
}
