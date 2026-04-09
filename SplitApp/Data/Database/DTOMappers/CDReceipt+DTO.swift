import CoreData

extension CDReceipt {

    /// Convert CoreData entity to DTO, including nested items.
    func toDTO() -> ReceiptDTO {
        let itemDTOs: [ReceiptItemDTO] = (items as? Set<CDReceiptItem>)?
            .map { $0.toDTO() } ?? []

        return ReceiptDTO(
            id: id!,
            eventId: eventId!,
            payerId: payerId!,
            title: title,
            totalAmount: totalAmount,
            createdAt: createdAt!,
            updatedAt: updatedAt!,
            items: itemDTOs
        )
    }

    /// Update CoreData entity from DTO (does not update nested items — handled in CoreDataStore).
    func update(from dto: ReceiptDTO) {
        self.id = dto.id
        self.eventId = dto.eventId
        self.payerId = dto.payerId
        self.title = dto.title
        self.totalAmount = dto.totalAmount
        self.createdAt = dto.createdAt
        self.updatedAt = dto.updatedAt
    }
}

extension CDReceiptItem {

    /// Convert CoreData entity to DTO.
    func toDTO() -> ReceiptItemDTO {
        let shareItemDTOs: [ShareItemDTO] = (shareItems as? Set<CDShareItem>)?
            .map { $0.toDTO() } ?? []

        return ReceiptItemDTO(
            id: id!,
            receiptId: receiptId!,
            name: name,
            cost: cost,
            shareItems: shareItemDTOs
        )
    }

    /// Update CoreData entity from DTO.
    func update(from dto: ReceiptItemDTO) {
        self.id = dto.id
        self.receiptId = dto.receiptId
        self.name = dto.name
        self.cost = dto.cost
    }
}

extension CDShareItem {

    /// Convert CoreData entity to DTO.
    func toDTO() -> ShareItemDTO {
        ShareItemDTO(
            id: id!,
            receiptItemId: receiptItemId!,
            userId: userId!,
            shareValue: shareValue
        )
    }

    /// Update CoreData entity from DTO.
    func update(from dto: ShareItemDTO) {
        self.id = dto.id
        self.receiptItemId = dto.receiptItemId
        self.userId = dto.userId
        self.shareValue = dto.shareValue
    }
}
