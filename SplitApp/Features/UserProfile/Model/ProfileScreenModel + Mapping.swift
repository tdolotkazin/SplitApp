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
    init(from response: ProfileResponse) {
        initials = response.initials
        email = response.email
        name = response.name
        eventsCountText = String(response.eventsCount)
        friendsCountText = String(response.friendsCount)
        closedBillsText = "₽\(response.closedBillsAmount)"
        openBillsText = "₽\(response.openBillsAmount)"
    }
}

extension ProfileScreenModel {
    static let mock = ProfileScreenModel(
        initials: "ИВ",
        email: "ivan@example.com",
        name: "Иван Волков",
        eventsCountText: "12",
        friendsCountText: "8",
        closedBillsText: "₽340",
        openBillsText: "₽34"
    )
}
