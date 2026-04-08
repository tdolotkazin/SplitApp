import SwiftUI

struct ReceiptParticipant: Identifiable, Hashable {
    let id: UUID
    var name: String
    var color: Color

    init(id: UUID = UUID(), name: String, color: Color = .accentColor) {
        self.id = id
        self.name = name
        self.color = color
    }
}
