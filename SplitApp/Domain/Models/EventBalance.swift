import Foundation

struct EventBalance: Codable, Hashable {
    let eventId: UUID
    let debitorId: UUID
    let creditorId: UUID
    let amount: Double
}
