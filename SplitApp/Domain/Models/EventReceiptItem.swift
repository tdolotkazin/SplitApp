import Foundation

struct EventReceiptItem: Hashable {
    let id: UUID
    let name: String
    let cost: Double
    let shares: [Share]

    init(id: UUID = UUID(), name: String, cost: Double, shares: [Share]) {
        self.id = id
        self.name = name
        self.cost = cost
        self.shares = shares
    }
}
