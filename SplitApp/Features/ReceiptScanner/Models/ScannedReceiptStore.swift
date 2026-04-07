import Foundation

/// Passes scanned receipt items from the camera flow to BillViewModel.
final class ScannedReceiptStore {
    static let shared = ScannedReceiptStore()
    private init() {}

    private(set) var pendingItems: [BillItem] = []

    func store(_ items: [BillItem]) {
        pendingItems = items
    }

    func consume() -> [BillItem] {
        let items = pendingItems
        pendingItems = []
        return items
    }
}
