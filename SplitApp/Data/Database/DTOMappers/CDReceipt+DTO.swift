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
            items: itemDTOs,
            imageUrl: imageUrl
        )
    }

    /// Update CoreData entity from DTO (does not update nested items — handled in CoreDataStore).
    func update(from dto: ReceiptDTO) {
        id = dto.id
        eventId = dto.eventId
        payerId = dto.payerId
        title = dto.title
        totalAmount = dto.totalAmount
        createdAt = dto.createdAt
        updatedAt = dto.updatedAt
        imageUrl = dto.imageUrl
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
        id = dto.id
        receiptId = dto.receiptId
        name = dto.name
        cost = dto.cost
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
        id = dto.id
        receiptItemId = dto.receiptItemId
        userId = dto.userId
        shareValue = dto.shareValue
    }
}
