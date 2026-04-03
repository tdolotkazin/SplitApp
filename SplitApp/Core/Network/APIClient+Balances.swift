import Foundation

extension APIClient {

    /// GET /api/events/{id}/balances
    func getEventBalances(eventId: UUID) async throws -> [EventBalanceDTO] {
        try await request(endpoint: .getBalances(eventId: eventId))
    }
}
