import Foundation

enum DebtType {
    case owes
    case owedBy
}

struct FriendDebt: Identifiable {
    let id: UUID
    let friend: Friend
    let amount: Decimal
    let type: DebtType

    init(id: UUID = UUID(), friend: Friend, amount: Decimal, type: DebtType) {
        self.id = id
        self.friend = friend
        self.amount = amount
        self.type = type
    }
}
