import Foundation

/// Локальное хранилище чеков (для работы без бэкенда)
final class LocalReceiptsStore {
    static let shared = LocalReceiptsStore()
    private init() {}

    private var receipts: [ReceiptDTO] = []

    /// Сохраняет чек локально
    func saveReceipt(_ receipt: ReceiptDTO) {
        receipts.append(receipt)
        print("💾 LocalReceiptsStore: Сохранен чек ID: \(receipt.id), eventId: \(receipt.eventId)")
        print("💾 LocalReceiptsStore: Всего чеков в хранилище: \(receipts.count)")
    }

    /// Возвращает все чеки для события
    func getReceipts(for eventId: UUID) -> [ReceiptDTO] {
        let filtered = receipts.filter { $0.eventId == eventId }
        print("💾 LocalReceiptsStore: Запрошены чеки для события: \(eventId)")
        print("💾 LocalReceiptsStore: Найдено чеков: \(filtered.count)")
        return filtered
    }

    /// Удаляет чек
    func deleteReceipt(id: UUID) {
        receipts.removeAll { $0.id == id }
    }

    /// Очищает все чеки
    func clear() {
        receipts.removeAll()
    }
}
