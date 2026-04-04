import CoreData

extension CoreDataStore {

    // MARK: - Upsert

    /// Insert or update a single payment from DTO.
    func upsertPayment(_ dto: PaymentDTO, in context: NSManagedObjectContext) throws {
        let fetchRequest: NSFetchRequest<CDPayment> = CDPayment.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", dto.id as CVarArg)
        fetchRequest.fetchLimit = 1

        let existing = try context.fetch(fetchRequest).first
        let payment = existing ?? CDPayment(context: context)
        payment.update(from: dto)

        // Link to event
        let eventFetch: NSFetchRequest<CDEvent> = CDEvent.fetchRequest()
        eventFetch.predicate = NSPredicate(format: "id == %@", dto.eventId as CVarArg)
        eventFetch.fetchLimit = 1
        payment.event = try context.fetch(eventFetch).first
    }

    /// Insert or update multiple payments from DTOs.
    func upsertPayments(_ dtos: [PaymentDTO], in context: NSManagedObjectContext) throws {
        for dto in dtos {
            try upsertPayment(dto, in: context)
        }
    }

    // MARK: - Fetch

    /// Fetch all payments for a given event.
    func fetchPayments(eventId: UUID, in context: NSManagedObjectContext) throws -> [CDPayment] {
        let fetchRequest: NSFetchRequest<CDPayment> = CDPayment.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "eventId == %@", eventId as CVarArg)
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \CDPayment.createdAt, ascending: false)]
        return try context.fetch(fetchRequest)
    }

    // MARK: - Delete

    /// Delete a payment by ID.
    func deletePayment(id: UUID, in context: NSManagedObjectContext) throws {
        let fetchRequest: NSFetchRequest<CDPayment> = CDPayment.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        fetchRequest.fetchLimit = 1
        guard let payment = try context.fetch(fetchRequest).first else { return }
        context.delete(payment)
    }
}
