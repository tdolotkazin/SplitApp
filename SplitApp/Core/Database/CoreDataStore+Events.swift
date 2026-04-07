import CoreData

extension CoreDataStore {


    /// Insert or update a single event from DTO.
    func upsertEvent(_ dto: EventDTO, in context: NSManagedObjectContext) throws {
        let fetchRequest: NSFetchRequest<CDEvent> = CDEvent.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", dto.id as CVarArg)
        fetchRequest.fetchLimit = 1

        let existing = try context.fetch(fetchRequest).first
        let event = existing ?? CDEvent(context: context)
        event.update(from: dto)

        // Sync participants
        let participantFetch: NSFetchRequest<CDUser> = CDUser.fetchRequest()
        participantFetch.predicate = NSPredicate(format: "id IN %@", dto.users)
        let participants = try context.fetch(participantFetch)
        event.participants = NSSet(array: participants)
    }

    /// Insert or update multiple events from DTOs.
    func upsertEvents(_ dtos: [EventDTO], in context: NSManagedObjectContext) throws {
        for dto in dtos {
            try upsertEvent(dto, in: context)
        }
    }


    /// Fetch a single event by ID.
    func fetchEvent(id: UUID, in context: NSManagedObjectContext) throws -> CDEvent? {
        let fetchRequest: NSFetchRequest<CDEvent> = CDEvent.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        fetchRequest.fetchLimit = 1
        return try context.fetch(fetchRequest).first
    }

    /// Fetch all events, sorted by creation date descending.
    func fetchAllEvents(in context: NSManagedObjectContext) throws -> [CDEvent] {
        let fetchRequest: NSFetchRequest<CDEvent> = CDEvent.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \CDEvent.createdAt, ascending: false)]
        return try context.fetch(fetchRequest)
    }


    /// Delete an event by ID (cascades to receipts and payments).
    func deleteEvent(id: UUID, in context: NSManagedObjectContext) throws {
        guard let event = try fetchEvent(id: id, in: context) else { return }
        context.delete(event)
    }
}
