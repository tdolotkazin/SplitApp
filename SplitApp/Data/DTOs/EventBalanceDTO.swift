import Foundation

struct EventBalanceDTO: Codable {
    let eventId: UUID
    let debitorId: UUID
    let creditorId: UUID
    let amount: Double

    enum CodingKeys: String, CodingKey {
        case amount
        case eventId = "event_id"
        case debitorId = "debitor_id"
        case creditorId = "creditor_id"
    }
}
