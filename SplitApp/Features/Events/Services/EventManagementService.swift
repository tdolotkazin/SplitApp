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

        // TODO: Fetch real balances via BalancesRepository when available
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

    // MARK: - Receipt Draft (mock for now)

    func fetchReceiptDraft() async -> ReceiptDraft {
        let participants = [
            ReceiptParticipant(initials: "АР", name: "Артём"),
            ReceiptParticipant(initials: "МС", name: "Маша"),
            ReceiptParticipant(initials: "ИВ", name: "Иван")
        ]

        let draft = [
            ReceiptLineItem(
                title: "Пицца\nМаргарита",
                amount: 12,
                participant: participants[0]
            ),
            ReceiptLineItem(
                title: "Пицца\nПепперони",
                amount: 13,
                participant: participants[1]
            ),
            ReceiptLineItem(
                title: "Газировка",
                amount: 8,
                participant: participants[2]
            )
        ]

        return ReceiptDraft(lineItems: draft, participants: participants)
    }
}
