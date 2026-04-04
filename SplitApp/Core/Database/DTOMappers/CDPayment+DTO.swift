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
        self.id = dto.id
        self.eventId = dto.eventId
        self.senderId = dto.senderId
        self.receiverId = dto.receiverId
        self.amount = dto.amount
        self.confirmed = dto.confirmed
        self.createdAt = dto.createdAt
    }
}
