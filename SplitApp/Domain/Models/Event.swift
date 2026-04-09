import Foundation

struct Event {
    let id: UUID
    let creatorId: UUID
    let name: String
    let date: Date
    let users: [User]
    var items: [EventReceiptItem]
    var receipts: [Receipt]
    let participants: [User]
    let participantIds: [UUID]

    let icon: String
    let participantsCount: Int
    let balanceDelta: Double

    init(
        id: UUID = UUID(),
        creatorId: UUID = UUID(),
        name: String,
        items: [EventReceiptItem] = [],
        receipts: [Receipt] = [],
        participants: [User] = [],
        participantIds: [UUID] = [],
        date: Date = Date(),
        icon: String = "📌",
        participantsCount: Int = 0,
        balanceDelta: Double = 0,
        users: [User] = []
    ) {
        self.id = id
        self.creatorId = creatorId
        self.name = name
        self.date = date
        self.items = items
        self.receipts = receipts
        self.participants = participants
        self.participantIds = participantIds
        self.icon = icon
        self.participantsCount = participantsCount
        self.balanceDelta = balanceDelta
        self.users = users
    }
}
