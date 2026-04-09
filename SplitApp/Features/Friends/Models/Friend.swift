import Foundation
import SwiftUI

struct Friend: Identifiable, Hashable {
    let id: UUID
    var name: String
    var initials: String
    var color: Color
    var avatarURL: URL?
    var userId: UUID?

    init(
        id: UUID = UUID(), name: String, initials: String, color: Color,
        avatarURL: URL? = nil, userId: UUID? = nil
    ) {
        self.id = id
        self.name = name
        self.initials = initials
        self.color = color
        self.avatarURL = avatarURL
        self.userId = userId
    }

    static func from(user: User) -> Friend {
        let initials = user.name.split(separator: " ")
            .prefix(2)
            .compactMap { $0.first }
            .map { String($0).uppercased() }
            .joined()

        return Friend(
            id: UUID(),
            name: user.name,
            initials: initials.isEmpty ? "?" : initials,
            color: generateColor(for: user.id),
            avatarURL: user.avatarUrl.flatMap { URL(string: $0) },
            userId: user.id
        )
    }

    static func from(localFriend: LocalFriend) -> Friend {
        let initials = localFriend.name.split(separator: " ")
            .prefix(2)
            .compactMap { $0.first }
            .map { String($0).uppercased() }
            .joined()

        return Friend(
            id: localFriend.id,
            name: localFriend.name,
            initials: initials.isEmpty ? "?" : initials,
            color: generateColor(for: localFriend.id),
            avatarURL: nil,
            userId: nil
        )
    }

    private static func generateColor(for id: UUID) -> Color {
        let colors: [Color] = [
            Color(hex: "#FFB5A7"), Color(hex: "#A7D8FF"), Color(hex: "#D4C5F9"), Color(hex: "#C9F7F5"),
            Color(hex: "#FFF4A7"), Color(hex: "#FFD4E5"), Color(hex: "#B5E7A0"), Color(hex: "#FFC4A3")
        ]
        let hash = abs(id.hashValue)
        return colors[hash % colors.count]
    }
}
