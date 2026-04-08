import Foundation

protocol PaymentsRepository {
    func listPayments(eventId: UUID) async throws -> [Payment]
    func createPayment(eventId: UUID, _ command: CreatePaymentCommand) async throws -> Payment
    func updatePayment(id: UUID, _ command: UpdatePaymentCommand) async throws -> Payment
}
