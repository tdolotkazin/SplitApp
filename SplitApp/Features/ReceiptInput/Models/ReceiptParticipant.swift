import Foundation

struct ReceiptParticipant: Identifiable, Hashable {
    let id: UUID
    let initials: String
    let name: String

    init(id: UUID = UUID(), initials: String, name: String) {
        self.id = id
        self.initials = initials
        self.name = name
    }
}
