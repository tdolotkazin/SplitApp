import Foundation

protocol EventManagementServiceProtocol {
    func fetchHomeData() async throws -> EventsHomeData
    func fetchReceiptDraft() async -> ReceiptDraft
}

struct EventManagementService: EventManagementServiceProtocol {

    private let eventsRepository: EventsRepositoryProtocol

    init(eventsRepository: EventsRepositoryProtocol = EventsRepository()) {
        self.eventsRepository = eventsRepository
    }

    // MARK: - Real Implementation

    func fetchHomeData() async throws -> EventsHomeData {
        let events = try await eventsRepository.listEvents(userId: nil)

        let balanceSummary = EventBalanceSummary(
            totalBalance: 0,
            owedToYou: 0,
            youOwe: 0
        )

        return EventsHomeData(
            balanceSummary: balanceSummary,
            events: events
        )
    }

    // MARK: - Receipt Draft

    func fetchReceiptDraft() async -> ReceiptDraft {
        // Пока так, в будущем будем брать из репозитория
        return ReceiptDraft(lineItems: [], participants: [])
    }
}
