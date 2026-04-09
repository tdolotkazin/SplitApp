import Foundation

struct BillListItem: Identifiable, Hashable {
    let id: UUID
    let emoji: String
    let title: String
    let subtitle: String
    let amount: Double
    let tone: EventAmountTone

    init(
        id: UUID = UUID(),
        emoji: String,
        title: String,
        subtitle: String,
        amount: Double,
        tone: EventAmountTone
    ) {
        self.id = id
        self.emoji = emoji
        self.title = title
        self.subtitle = subtitle
        self.amount = amount
        self.tone = tone
    }
}
