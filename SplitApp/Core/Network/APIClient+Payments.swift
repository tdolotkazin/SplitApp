import Foundation

extension APIClient {

    /// POST /api/events/{id}/payments
    func createPayment(eventId: UUID, _ request: CreatePaymentRequest) async throws -> PaymentDTO {
        try await self.request(endpoint: .createPayment(eventId: eventId), body: request)
    }

    /// GET /api/events/{id}/payments
    func listPayments(eventId: UUID) async throws -> [PaymentDTO] {
        try await request(endpoint: .listPayments(eventId: eventId))
    }

    /// PATCH /api/payments/{id}
    func updatePayment(id: UUID, _ request: UpdatePaymentRequest) async throws -> PaymentDTO {
        try await self.request(endpoint: .updatePayment(id: id), body: request)
    }
}
