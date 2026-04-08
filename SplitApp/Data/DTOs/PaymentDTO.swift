import Foundation

struct PaymentDTO: Codable, Identifiable {
    let id: UUID
    let eventId: UUID
    let senderId: UUID
    let receiverId: UUID
    let amount: Double
    let confirmed: Bool
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, amount, confirmed
        case eventId = "event_id"
        case senderId = "sender_id"
        case receiverId = "receiver_id"
        case createdAt = "created_at"
    }
}

struct CreatePaymentRequest: Codable {
    let senderId: UUID
    let receiverId: UUID
    let amount: Double

    enum CodingKeys: String, CodingKey {
        case amount
        case senderId = "sender_id"
        case receiverId = "receiver_id"
    }
}

struct UpdatePaymentRequest: Codable {
    let confirmed: Bool
}
