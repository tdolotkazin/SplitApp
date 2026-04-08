import Foundation

struct ReceiptLineItem: Identifiable {
    let id: UUID
    var title: String
    var amount: Double
    var participant: ReceiptParticipant

    init(id: UUID = UUID(), title: String, amount: Double, participant: ReceiptParticipant) {
        self.id = id
        self.title = title
        self.amount = amount
        self.participant = participant
    }
}
