import Foundation

struct Position {
    let id: UUID
    let name: String
    let amount: Double
    let participants: [PositionParticipant]

    init(name: String, amount: Double, participants: [PositionParticipant]) {
        self.id = UUID()
        self.name = name
        self.amount = amount
        self.participants = participants
    }
}
