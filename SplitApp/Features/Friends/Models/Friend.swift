import Foundation
import SwiftUI

struct Friend: Identifiable, Hashable {
    let id: UUID
    var name: String
    var initials: String
    var color: Color
    var avatarURL: URL?

    init(
        id: UUID = UUID(),
        name: String,
        initials: String,
        color: Color,
        avatarURL: URL? = nil
    ) {
        self.id = id
        self.name = name
        self.initials = initials
        self.color = color
        self.avatarURL = avatarURL
    }
}
