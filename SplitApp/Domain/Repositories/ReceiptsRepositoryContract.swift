import Foundation

enum ReceiptFetchPolicy {
    case localOnly
    case refreshIfPossible
}

protocol ReceiptsRepository {
    func getCachedReceipts(eventId: UUID) async throws -> [Receipt]
    func refreshReceipts(eventId: UUID) async throws -> [Receipt]
    func getCachedReceipt(id: UUID) async throws -> Receipt
    func getReceipt(id: UUID, eventId: UUID, policy: ReceiptFetchPolicy) async throws -> Receipt
    func createReceipt(eventId: UUID, _ command: CreateReceiptCommand) async throws -> Receipt
    func updateReceipt(id: UUID, _ command: UpdateReceiptCommand) async throws -> Receipt
    func deleteReceipt(id: UUID) async throws
}
