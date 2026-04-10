import Foundation

struct ProfileScreenModel {
    let initials: String
    let email: String
    let name: String
    let eventsCountText: String
    let friendsCountText: String
    let avatarURL: URL?
}

extension ProfileScreenModel {
    static let mock = ProfileScreenModel(
        initials: "ИВ",
        email: "ivan@example.com",
        name: "Иван Волков",
        eventsCountText: "12",
        friendsCountText: "8",
        avatarURL: nil
    )
}
