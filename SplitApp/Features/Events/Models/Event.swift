import Foundation

struct Event {
    let id: UUID
    let name: String
    let date: Date
    var positions: [Position]
    var bill: Bill

    let icon: String
    let participantsCount: Int
    let balanceDelta: Double

    init(
        name: String,
        positions: [Position],
        date: Date = Date(),
        icon: String = "📌",
        participantsCount: Int = 0,
        balanceDelta: Double = 0
    ) {
        let eventID = UUID()
        self.id = eventID
        self.name = name
        self.date = date
        self.positions = positions
        self.bill = Bill(eventId: eventID, positions: positions)
        self.icon = icon
        self.participantsCount = participantsCount
        self.balanceDelta = balanceDelta
    }
}
