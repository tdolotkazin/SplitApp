import Foundation

struct ProfileScreenModel {
    let initials: String
    let email: String
    let name: String
    let eventsCountText: String
    let friendsCountText: String
    let closedBillsText: String
    let openBillsText: String

}

extension ProfileScreenModel {
    static let mock = ProfileScreenModel(
        initials: "ИВ",
        email: "ivan@example.com",
        name: "Иван Волков",
        eventsCountText: "12",
        friendsCountText: "8",
        closedBillsText: "₽340",

    )
}
