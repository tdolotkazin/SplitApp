import Foundation

protocol BalancesRepository {
    /// Online-first: attempts network, falls back to cached balances if available.
    func getEventBalances(eventId: UUID) async throws -> [EventBalance]

    /// Returns only locally cached balances.
    func getCachedEventBalances(eventId: UUID) async throws -> [EventBalance]
}
