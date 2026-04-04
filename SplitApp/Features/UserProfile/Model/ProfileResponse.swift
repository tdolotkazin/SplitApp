import Foundation

struct ProfileResponse: Decodable {
    let initials: String
    let email: String
    let name: String
    let eventsCount: Int
    let friendsCount: Int
    let closedBillsAmount: Decimal
    let openBillsAmount: Decimal
}
