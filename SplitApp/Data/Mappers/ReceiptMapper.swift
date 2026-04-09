import Foundation

enum ReceiptMapper {
    static func mapToDomain(dto: ReceiptDTO, items: [EventReceiptItem]) -> Receipt {
        Receipt(
            id: dto.id,
            eventId: dto.eventId,
            payerId: dto.payerId,
            title: dto.title,
            totalAmount: dto.totalAmount,
            createdAt: dto.createdAt,
            items: items,
            imageURL: dto.imageUrl
        )
    }

    static func mapItemToDomain(dto: ReceiptItemDTO, shares: [Share]) -> EventReceiptItem {
        EventReceiptItem(
            id: dto.id,
            name: dto.name ?? "",
            cost: dto.cost,
            shares: shares
        )
    }

    static func mapShareToDomain(dto: ShareItemDTO) -> Share {
        Share(
            id: dto.id,
            userId: dto.userId,
            shareValue: dto.shareValue
        )
    }
}
