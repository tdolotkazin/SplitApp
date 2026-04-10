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
    let imageUrl: String?

    enum CodingKeys: String, CodingKey {
        case id, title, items
        case eventId = "event_id"
        case payerId = "payer_id"
        case totalAmount = "total_amount"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case imageUrl = "image_url"
    }
}

struct ReceiptItemDTO: Codable, Identifiable {
    let id: UUID
    let receiptId: UUID
    let name: String?
    let cost: Double
    let shareItems: [ShareItemDTO]

    enum CodingKeys: String, CodingKey {
        case id, name, cost
        case receiptId = "receipt_id"
        case shareItems = "share_items"
    }

    init(
        id: UUID,
        receiptId: UUID,
        name: String?,
        cost: Double,
        shareItems: [ShareItemDTO]
    ) {
        self.id = id
        self.receiptId = receiptId
        self.name = name
        self.cost = cost
        self.shareItems = shareItems
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let id = try container.decode(UUID.self, forKey: .id)
        let receiptId = try container.decode(UUID.self, forKey: .receiptId)
        let name = try container.decodeIfPresent(String.self, forKey: .name)
        let cost = try container.decode(Double.self, forKey: .cost)

        if let userIds = try? container.decode([UUID].self, forKey: .shareItems) {
            self.init(
                id: id,
                receiptId: receiptId,
                name: name,
                cost: cost,
                shareItems: Self.makeNormalizedShareItems(
                    for: userIds,
                    receiptItemId: id
                )
            )
            return
        }

        self.init(
            id: id,
            receiptId: receiptId,
            name: name,
            cost: cost,
            shareItems: try container.decode([ShareItemDTO].self, forKey: .shareItems)
        )
    }

    private static func makeNormalizedShareItems(
        for userIds: [UUID],
        receiptItemId: UUID
    ) -> [ShareItemDTO] {
        guard !userIds.isEmpty else { return [] }

        let scale = 1_000_000
        let baseScaled = scale / userIds.count
        let lastScaled = scale - baseScaled * (userIds.count - 1)

        return userIds.enumerated().map { index, userId in
            ShareItemDTO(
                id: UUID(),
                receiptItemId: receiptItemId,
                userId: userId,
                shareValue: Double(index == userIds.count - 1 ? lastScaled : baseScaled) / Double(scale)
            )
        }
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

    init(id: UUID, receiptItemId: UUID, userId: UUID, shareValue: Double) {
        self.id = id
        self.receiptItemId = receiptItemId
        self.userId = userId
        self.shareValue = shareValue
    }

    // Server returns share_items as plain UUID strings (e.g. ["uuid1", "uuid2"])
    init(from decoder: Decoder) throws {
        if let userId = try? decoder.singleValueContainer().decode(UUID.self) {
            self.userId = userId
            self.id = UUID()
            self.receiptItemId = UUID()
            self.shareValue = 1.0
        } else {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.id = try container.decode(UUID.self, forKey: .id)
            self.receiptItemId = try container.decode(UUID.self, forKey: .receiptItemId)
            self.userId = try container.decode(UUID.self, forKey: .userId)
            self.shareValue = try container.decode(Double.self, forKey: .shareValue)
        }
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

struct ReceiptImageUploadResponseDTO: Codable {
    let imageUrl: String

    enum CodingKeys: String, CodingKey {
        case imageUrl = "image_url"
    }
}
