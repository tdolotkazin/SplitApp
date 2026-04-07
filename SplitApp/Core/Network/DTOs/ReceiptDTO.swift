import Foundation

struct ReceiptDTO: Codable, Identifiable {
    let id: UUID
    let eventId: UUID
    let payerId: UUID
    let title: String?
    let totalAmount: Double
    let createdAt: Date
    let updatedAt: Date
    let items: [ReceiptItemDTO]

    enum CodingKeys: String, CodingKey {
        case id, title, items
        case eventId = "event_id"
        case payerId = "payer_id"
        case totalAmount = "total_amount"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct ReceiptItemDTO: Codable, Identifiable {
    let id: UUID
    let receiptId: UUID
    let name: String?
    let cost: Double
    let shareItems: [UUID]

    enum CodingKeys: String, CodingKey {
        case id, name, cost
        case receiptId = "receipt_id"
        case shareItems = "share_items"
    }
}

struct ShareItemDTO: Codable, Identifiable {
    let id: UUID
    let receiptItemId: UUID
    let userId: UUID
    let shareValue: Double

    enum CodingKeys: String, CodingKey {
        case id
        case receiptItemId = "receipt_item_id"
        case userId = "user_id"
        case shareValue = "share_value"
    }
}

struct CreateReceiptRequest: Codable {
    let payerId: UUID
    let title: String?
    let totalAmount: Double
    let items: [CreateReceiptItemRequest]

    enum CodingKeys: String, CodingKey {
        case title, items
        case payerId = "payer_id"
        case totalAmount = "total_amount"
    }
}

struct CreateReceiptItemRequest: Codable {
    let name: String?
    let cost: Double
    let shareItems: [CreateShareItemRequest]

    enum CodingKeys: String, CodingKey {
        case name, cost
        case shareItems = "share_items"
    }
}

struct CreateShareItemRequest: Codable {
    let userId: UUID
    let shareValue: Double

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case shareValue = "share_value"
    }
}

struct UpdateReceiptRequest: Codable {
    let title: String?
    let totalAmount: Double?
    let items: [CreateReceiptItemRequest]?

    enum CodingKeys: String, CodingKey {
        case title, items
        case totalAmount = "total_amount"
    }
}
