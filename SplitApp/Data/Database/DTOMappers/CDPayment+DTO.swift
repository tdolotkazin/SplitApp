import CoreData

extension CDPayment {
    /// Convert CoreData entity to DTO.
    func toDTO() -> PaymentDTO {
        PaymentDTO(
            id: id!,
            eventId: eventId!,
            senderId: senderId!,
            receiverId: receiverId!,
            amount: amount,
            confirmed: confirmed,
            createdAt: createdAt!
        )
    }

    /// Update CoreData entity from DTO.
    func update(from dto: PaymentDTO) {
        id = dto.id
        eventId = dto.eventId
        senderId = dto.senderId
        receiverId = dto.receiverId
        amount = dto.amount
        confirmed = dto.confirmed
        createdAt = dto.createdAt
    }
}
