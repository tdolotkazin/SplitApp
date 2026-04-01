import Foundation

enum ParticipantTone: Hashable {
    case orange
    case mint
    case indigo
    case neutral
}

struct ReceiptParticipant: Identifiable, Hashable {
    let id: UUID
    let initials: String
    let name: String
    let tone: ParticipantTone

    init(id: UUID = UUID(), initials: String, name: String, tone: ParticipantTone) {
        self.id = id
        self.initials = initials
        self.name = name
        self.tone = tone
    }
}
