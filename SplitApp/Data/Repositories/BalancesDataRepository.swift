import Foundation

final class BalancesDataRepository: BalancesRepository {
    private let apiClient: APIClient
    private let userDefaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(apiClient: APIClient = .shared, userDefaults: UserDefaults = .standard) {
        self.apiClient = apiClient
        self.userDefaults = userDefaults
    }

    func getEventBalances(eventId: UUID) async throws -> [EventBalance] {
        do {
            let dtos: [EventBalanceDTO] = try await apiClient.request(endpoint: GetBalancesEndpoint(eventId: eventId))
            let balances = dtos.map(EventBalanceMapper.mapToDomain(dto:))
            try cache(balances, eventId: eventId)
            return balances
        } catch {
            let cached = try await getCachedEventBalances(eventId: eventId)
            if cached.isEmpty {
                throw RepositoryError.offlineNoCache
            }
            return cached
        }
    }

    func getCachedEventBalances(eventId: UUID) async throws -> [EventBalance] {
        guard let data = userDefaults.data(forKey: cacheKey(eventId: eventId)) else {
            return []
        }
        return try decoder.decode([EventBalance].self, from: data)
    }

    private func cache(_ balances: [EventBalance], eventId: UUID) throws {
        let data = try encoder.encode(balances)
        userDefaults.set(data, forKey: cacheKey(eventId: eventId))
    }

    private func cacheKey(eventId: UUID) -> String {
        "splitapp.balances.\(eventId.uuidString)"
    }
}
