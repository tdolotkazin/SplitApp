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
        self.initials = response.initials
        self.email = response.email
        self.name = response.name
        self.eventsCountText = String(response.eventsCount)
        self.friendsCountText = String(response.friendsCount)
        self.closedBillsText = "€\(response.closedBillsAmount)"
        self.openBillsText = "€\(response.openBillsAmount)"
    }
}

