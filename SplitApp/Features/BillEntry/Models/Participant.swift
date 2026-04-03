import SwiftUI

struct Participant: Identifiable, Hashable {
    let id: UUID
    var name: String
    var initials: String
    var color: Color

    init(id: UUID = UUID(), name: String, initials: String, color: Color) {
        self.id = id
        self.name = name
        self.initials = initials
        self.color = color
    }
}
