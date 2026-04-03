import Foundation

extension APIClient {

    /// POST /api/events/{id}/receipts
    func createReceipt(eventId: UUID, _ request: CreateReceiptRequest) async throws -> ReceiptDTO {
        try await self.request(endpoint: .createReceipt(eventId: eventId), body: request)
    }

    /// GET /api/events/{id}/receipts
    func listReceipts(eventId: UUID) async throws -> [ReceiptDTO] {
        try await request(endpoint: .listReceipts(eventId: eventId))
    }

    /// PATCH /api/receipts/{id}
    func updateReceipt(id: UUID, _ request: UpdateReceiptRequest) async throws -> ReceiptDTO {
        try await self.request(endpoint: .updateReceipt(id: id), body: request)
    }

    /// DELETE /api/receipts/{id}
    func deleteReceipt(id: UUID) async throws {
        try await requestVoid(endpoint: .deleteReceipt(id: id))
    }
}
