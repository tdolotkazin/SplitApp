import CoreData

extension CoreDataStore {


    /// Insert or update a single receipt from DTO, including nested items and share items.
    func upsertReceipt(_ dto: ReceiptDTO, in context: NSManagedObjectContext) throws {
        let fetchRequest: NSFetchRequest<CDReceipt> = CDReceipt.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", dto.id as CVarArg)
        fetchRequest.fetchLimit = 1

        let existing = try context.fetch(fetchRequest).first
        let receipt = existing ?? CDReceipt(context: context)
        receipt.update(from: dto)

        // Link to event
        let eventFetch: NSFetchRequest<CDEvent> = CDEvent.fetchRequest()
        eventFetch.predicate = NSPredicate(format: "id == %@", dto.eventId as CVarArg)
        eventFetch.fetchLimit = 1
        receipt.event = try context.fetch(eventFetch).first

        // Remove old items before upserting new ones
        if let oldItems = receipt.items as? Set<CDReceiptItem> {
            for item in oldItems {
                context.delete(item)
            }
        }

        // Create receipt items
        for itemDTO in dto.items {
            let receiptItem = CDReceiptItem(context: context)
            receiptItem.id = itemDTO.id
            receiptItem.receiptId = dto.id
            receiptItem.name = itemDTO.name
            receiptItem.cost = itemDTO.cost
            receiptItem.receipt = receipt
        }
    }

    /// Insert or update multiple receipts from DTOs.
    func upsertReceipts(_ dtos: [ReceiptDTO], in context: NSManagedObjectContext) throws {
        for dto in dtos {
            try upsertReceipt(dto, in: context)
        }
    }


    /// Fetch all receipts for a given event.
    func fetchReceipts(eventId: UUID, in context: NSManagedObjectContext) throws -> [CDReceipt] {
        let fetchRequest: NSFetchRequest<CDReceipt> = CDReceipt.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "eventId == %@", eventId as CVarArg)
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \CDReceipt.createdAt, ascending: false)]
        return try context.fetch(fetchRequest)
    }


    /// Delete a receipt by ID (cascades to items and share items).
    func deleteReceipt(id: UUID, in context: NSManagedObjectContext) throws {
        let fetchRequest: NSFetchRequest<CDReceipt> = CDReceipt.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        fetchRequest.fetchLimit = 1
        guard let receipt = try context.fetch(fetchRequest).first else { return }
        context.delete(receipt)
    }
}
