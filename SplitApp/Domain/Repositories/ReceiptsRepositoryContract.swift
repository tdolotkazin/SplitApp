import Foundation

enum ReceiptFetchPolicy {
    case localOnly
    case refreshIfPossible
}

protocol ReceiptsRepository {
    /// Returns cached receipts only.
    func getCachedReceipts(eventId: UUID) async throws -> [Receipt]
    /// Forces network refresh and updates local cache.
    func refreshReceipts(eventId: UUID) async throws -> [Receipt]
    /// Returns cached receipt only.
    func getCachedReceipt(id: UUID) async throws -> Receipt
    /// Online-first policy controlled by `policy`.
    func getReceipt(id: UUID, eventId: UUID, policy: ReceiptFetchPolicy) async throws -> Receipt
    func createReceipt(eventId: UUID, _ command: CreateReceiptCommand) async throws -> Receipt
    func updateReceipt(id: UUID, _ command: UpdateReceiptCommand) async throws -> Receipt
    func deleteReceipt(id: UUID) async throws
}
