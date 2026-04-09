import Foundation

enum LocalDebtDirection: String, Codable, Hashable {
    case owes
    case owedBy
}

struct LocalFriendDebt: Codable, Hashable, Identifiable {
    let id: UUID
    let userId: UUID
    let amount: Double
    let direction: LocalDebtDirection

    init(id: UUID = UUID(), userId: UUID, amount: Double, direction: LocalDebtDirection) {
        self.id = id
        self.userId = userId
        self.amount = amount
        self.direction = direction
    }
}
