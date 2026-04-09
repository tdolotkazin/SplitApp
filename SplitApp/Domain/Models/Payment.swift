import Foundation

struct Payment: Hashable, Identifiable {
    let id: UUID
    let eventId: UUID
    let senderId: UUID
    let receiverId: UUID
    let amount: Double
    let confirmed: Bool
    let createdAt: Date
}
