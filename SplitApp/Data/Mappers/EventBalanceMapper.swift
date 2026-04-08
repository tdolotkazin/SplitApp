import Foundation

enum EventBalanceMapper {
    static func mapToDomain(dto: EventBalanceDTO) -> EventBalance {
        EventBalance(
            eventId: dto.eventId,
            debitorId: dto.debitorId,
            creditorId: dto.creditorId,
            amount: dto.amount
        )
    }
}
