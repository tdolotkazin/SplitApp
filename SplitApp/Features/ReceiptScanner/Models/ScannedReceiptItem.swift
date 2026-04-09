import Foundation

struct ScannedReceiptItem: Identifiable {
    let id = UUID()
    let name: String
    let amount: Decimal
}
