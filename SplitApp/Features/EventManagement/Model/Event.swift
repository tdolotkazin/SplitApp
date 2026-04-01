import Foundation

struct Event {
    let id: UUID
    let name: String
    let date: Date
    var positions: [Position]
    var bill: Bill

    let icon: String
    let participantsCount: Int
    let relativeDateText: String
    let balanceDelta: Double?

    init(
        name: String,
        positions: [Position],
        bill: Bill,
        icon: String = "📌",
        participantsCount: Int = 0,
        relativeDateText: String = "сегодня",
        balanceDelta: Double? = nil
    ) {
        self.id = UUID()
        self.name = name
        self.date = Date()
        self.positions = positions
        self.bill = bill
        self.icon = icon
        self.participantsCount = participantsCount
        self.relativeDateText = relativeDateText
        self.balanceDelta = balanceDelta
    }

    init(
        name: String,
        positions: [Position],
        icon: String = "📌",
        participantsCount: Int = 0,
        relativeDateText: String = "сегодня",
        balanceDelta: Double? = nil
    ) {
        let eventID = UUID()
        self.id = eventID
        self.name = name
        self.date = Date()
        self.positions = positions
        self.bill = Bill(eventId: eventID, positions: positions)
        self.icon = icon
        self.participantsCount = participantsCount
        self.relativeDateText = relativeDateText
        self.balanceDelta = balanceDelta
    }
}
