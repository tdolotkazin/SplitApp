import Foundation

struct BillItem: Identifiable {
    let id: UUID
    var name: String
    var amount: Decimal
    var currency: String
    var assignedTo: Participant?
    var isEditing: Bool

    init(
        id: UUID = UUID(),
        name: String = "",
        amount: Decimal = 0,
        currency: String = "€",
        assignedTo: Participant? = nil,
        isEditing: Bool = false
    ) {
        self.id = id
        self.name = name
        self.amount = amount
        self.currency = currency
        self.assignedTo = assignedTo
        self.isEditing = isEditing
    }
}
