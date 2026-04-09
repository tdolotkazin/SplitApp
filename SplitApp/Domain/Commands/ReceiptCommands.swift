import Foundation

struct CreateReceiptCommand {
    let payerId: UUID
    let title: String?
    let totalAmount: Double
    let items: [CreateReceiptItemCommand]
}

struct CreateReceiptItemCommand {
    let name: String?
    let cost: Double
    let shareItems: [CreateShareItemCommand]
}

struct CreateShareItemCommand {
    let userId: UUID
    let shareValue: Double
}

struct UpdateReceiptCommand {
    let title: String?
    let totalAmount: Double?
    let items: [CreateReceiptItemCommand]?
}
