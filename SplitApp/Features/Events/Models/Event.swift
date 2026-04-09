import Foundation

struct Event {
    let id: UUID
    let name: String
    let date: Date
    var positions: [Position]
    var bill: Bill
    let users: [User]

    let icon: String
    let participantsCount: Int
    let balanceDelta: Double

    init(
        id: UUID = UUID(),
        name: String,
        positions: [Position],
        date: Date = Date(),
        icon: String = "📌",
        participantsCount: Int = 0,
        balanceDelta: Double = 0,
        users: [User] = []
    ) {
        self.id = id
        self.name = name
        self.date = date
        self.positions = positions
        self.bill = Bill(eventId: id, positions: positions)
        self.icon = icon
        self.participantsCount = participantsCount
        self.balanceDelta = balanceDelta
        self.users = users
    }
}
