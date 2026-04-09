import Foundation

enum PaymentMapper {
    static func mapToDomain(dto: PaymentDTO) -> Payment {
        Payment(
            id: dto.id,
            eventId: dto.eventId,
            senderId: dto.senderId,
            receiverId: dto.receiverId,
            amount: dto.amount,
            confirmed: dto.confirmed,
            createdAt: dto.createdAt
        )
    }
}
