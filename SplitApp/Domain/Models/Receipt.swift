import Foundation

struct Receipt: Hashable, Identifiable {
    let id: UUID
    let eventId: UUID
    let payerId: UUID
    let title: String?
    let totalAmount: Double
    let createdAt: Date
    let items: [EventReceiptItem]
    let imageURL: String?

    init(
        id: UUID = UUID(),
        eventId: UUID,
        payerId: UUID,
        title: String?,
        totalAmount: Double,
        createdAt: Date = Date(),
        items: [EventReceiptItem] = [],
        imageURL: String? = nil
    ) {
        self.id = id
        self.eventId = eventId
        self.payerId = payerId
        self.title = title
        self.totalAmount = totalAmount
        self.createdAt = createdAt
        self.items = items
        self.imageURL = imageURL
    }
}
