import Foundation
import CoreData

final class EventsDataRepository: EventsRepository {
    private let apiClient: APIClient
    private let coreDataStore: CoreDataStore

    init(apiClient: APIClient = .shared, coreDataStore: CoreDataStore = .shared) {
        self.apiClient = apiClient
        self.coreDataStore = coreDataStore
    }

    func createEvent(_ command: CreateEventCommand) async throws -> Event {
        let request = CreateEventRequest(creatorId: command.creatorId, name: command.name)
        let dto: EventDTO = try await apiClient.request(endpoint: CreateEventEndpoint(), body: request)
        try await coreDataStore.performBackground { [weak self] context in
            try self?.upsertEvent(dto, in: context)
        }
        return try await refreshEvent(id: dto.id)
    }

    func listEvents(userId: UUID? = nil) async throws -> [Event] {
        do {
            return try await refreshEvents(userId: userId)
        } catch {
            let cachedEvents = try await getCachedEvents(userId: userId)

            if cachedEvents.isEmpty {
                throw error
            }

            return cachedEvents
        }
    }

    func refreshEvents(userId: UUID? = nil) async throws -> [Event] {
        let dtos: [EventDTO] = try await apiClient.request(endpoint: ListEventsEndpoint(userId: userId))

        try await coreDataStore.performBackground { [weak self] context in
            try self?.upsertEvents(dtos, in: context)
        }

        return try await getCachedEvents(userId: userId)
    }

    func getEvent(id: UUID) async throws -> Event {
        do {
            return try await refreshEvent(id: id)
        } catch {
            if let event = try await getCachedEvent(id: id) {
                return event
            }

            throw error
        }
    }

    func getCachedEvent(id: UUID) async throws -> Event? {
        try await coreDataStore.performBackground { context in
            let fetchRequest: NSFetchRequest<CDEvent> = CDEvent.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            fetchRequest.fetchLimit = 1
            let cdEvent = try context.fetch(fetchRequest).first
            return cdEvent.flatMap { EventMapper.mapToDomain(cdEvent: $0) }
        }
    }

    func refreshEvent(id: UUID) async throws -> Event {
        let dto: EventDTO = try await apiClient.request(endpoint: GetEventEndpoint(id: id))
        try await coreDataStore.performBackground { [weak self] context in
            try self?.upsertEvent(dto, in: context)
        }

        if let cached = try await getCachedEvent(id: id) {
            return cached
        }

        return EventMapper.mapToDomain(dto: dto)
    }

    func updateEvent(id: UUID, _ command: UpdateEventCommand) async throws -> Event {
        let request = UpdateEventRequest(isClosed: command.isClosed, name: command.name)
        let dto: EventDTO = try await apiClient.request(endpoint: UpdateEventEndpoint(id: id), body: request)
        try await coreDataStore.performBackground { [weak self] context in
            try self?.upsertEvent(dto, in: context)
        }
        return try await refreshEvent(id: dto.id)
    }

    func addParticipants(eventId: UUID, _ command: AddParticipantsCommand) async throws -> [User] {
        let request = AddParticipantsRequest(userIds: command.userIds)
        let dtos: [UserDTO] = try await apiClient.request(
            endpoint: AddParticipantsEndpoint(eventId: eventId),
            body: request
        )
        try await coreDataStore.performBackground { [weak self] context in
            try self?.upsertUsers(dtos, in: context)

            let eventFetch: NSFetchRequest<CDEvent> = CDEvent.fetchRequest()
            eventFetch.predicate = NSPredicate(format: "id == %@", eventId as CVarArg)
            eventFetch.fetchLimit = 1

            let userIds = dtos.map(\.id)
            let participantFetch: NSFetchRequest<CDUser> = CDUser.fetchRequest()
            participantFetch.predicate = NSPredicate(format: "id IN %@", userIds as NSArray)

            if let event = try context.fetch(eventFetch).first {
                let existing = event.participants as? Set<CDUser> ?? []
                let participants = try context.fetch(participantFetch)
                event.participants = NSSet(array: Array(existing.union(participants)))
            }
        }
        return dtos.map { UserMapper.mapToDomain(dto: $0) }
    }

    func removeParticipant(eventId: UUID, userId: UUID) async throws {
        try await apiClient.requestVoid(endpoint: RemoveParticipantEndpoint(eventId: eventId, userId: userId))
    }

    private func upsertEvent(_ dto: EventDTO, in context: NSManagedObjectContext) throws {
        let fetchRequest: NSFetchRequest<CDEvent> = CDEvent.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", dto.id as CVarArg)
        fetchRequest.fetchLimit = 1

        let existing = try context.fetch(fetchRequest).first
        let event = existing ?? CDEvent(context: context)
        event.update(from: dto)

        if let participantDTOs = dto.participants {
            try upsertUsers(participantDTOs, in: context)
        }

        let participantIds = dto.participants?.map(\.id) ?? dto.users
        guard !participantIds.isEmpty else {
            event.participants = NSSet()
            return
        }

        let participantFetch: NSFetchRequest<CDUser> = CDUser.fetchRequest()
        participantFetch.predicate = NSPredicate(format: "id IN %@", participantIds as NSArray)
        let participants = try context.fetch(participantFetch)
        event.participants = NSSet(array: participants)
    }

    private func upsertEvents(_ dtos: [EventDTO], in context: NSManagedObjectContext) throws {
        for dto in dtos {
            try upsertEvent(dto, in: context)
        }
    }

    private func upsertUsers(_ dtos: [UserDTO], in context: NSManagedObjectContext) throws {
        for dto in dtos {
            let fetchRequest: NSFetchRequest<CDUser> = CDUser.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", dto.id as CVarArg)
            fetchRequest.fetchLimit = 1

            let existing = try context.fetch(fetchRequest).first
            let user = existing ?? CDUser(context: context)
            user.update(from: dto)
        }
    }

    private func getCachedEvents(userId: UUID?) async throws -> [Event] {
        try await coreDataStore.performBackground { context in
            let fetchRequest: NSFetchRequest<CDEvent> = CDEvent.fetchRequest()
            fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \CDEvent.createdAt, ascending: false)]
            let cdEvents = try context.fetch(fetchRequest)
                .filter { event in
                    guard let userId else { return true }
                    let participantIds = (event.participants as? Set<CDUser>)?.compactMap(\.id) ?? []
                    return participantIds.contains(userId)
                }
            return cdEvents.compactMap { EventMapper.mapToDomain(cdEvent: $0) }
        }
    }
}
