import SwiftUI

struct CurrentUser {
    let id: UUID
    let name: String
    let initials: String
    let avatarURL: URL?
    let color: Color
}

final class CurrentUserStore {
    static let shared = CurrentUserStore()

    private init() {}

    private static let avatarURL =
        URL(string: "https://avatars.yandex.net/get-yapic/18057972/OxsEFr6TY2BhCCIjGojNlINJEY-1/islands-200")

    let user = CurrentUser(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
        name: "Иван Волков",
        initials: "ИВ",
        avatarURL: CurrentUserStore.avatarURL,
        color: Color(hex: "#7CB342")
    )
}

extension CurrentUser {
    func toParticipant() -> Participant {
        Participant(
            id: id,
            name: name,
            initials: initials,
            color: color,
            avatarURL: avatarURL
        )
    }
}
