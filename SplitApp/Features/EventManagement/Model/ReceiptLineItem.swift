import Foundation

struct ReceiptLineItem: Identifiable, Hashable {
    let id: UUID
    var title: String
    var amount: Double
    var amountInput: String
    var participant: ReceiptParticipant?
    var isPlaceholder: Bool

    init(
        id: UUID = UUID(),
        title: String,
        amount: Double,
        amountInput: String? = nil,
        participant: ReceiptParticipant?,
        isPlaceholder: Bool = false
    ) {
        self.id = id
        self.title = title
        self.amount = amount
        self.amountInput = amountInput ?? Self.defaultAmountInput(from: amount)
        self.participant = participant
        self.isPlaceholder = isPlaceholder
    }
}

private extension ReceiptLineItem {
    static func defaultAmountInput(from amount: Double) -> String {
        if amount.rounded() == amount {
            return String(Int(amount))
        }

        return String(format: "%.2f", amount).replacingOccurrences(of: ".", with: ",")
    }
}
