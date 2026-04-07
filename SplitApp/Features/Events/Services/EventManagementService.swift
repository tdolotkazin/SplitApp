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
        // Try real API first, fall back to mocks if empty or failed
        var events: [Event]
        do {
            events = try await eventsRepository.listEvents(userId: nil)
        } catch {
            print("⚠️ API недоступен, используем моковые данные: \(error.localizedDescription)")
            events = []
        }

        if events.isEmpty {
            events = Self.mockEvents()
        }

        // Fetch real balances via BalancesRepository when available
        let balanceSummary = EventBalanceSummary(
            totalBalance: 34.50,
            owedToYou: 89.00,
            youOwe: 54.50
        )

        return EventsHomeData(
            balanceSummary: balanceSummary,
            events: events
        )
    }

    // MARK: - Mock Data (remove when backend is populated)

    private static func mockEvents() -> [Event] {
        let calendar = Calendar.current
        let now = Date()

        return [
            Event(
                name: "Пицца-пятница",
                positions: [],
                date: calendar.date(byAdding: .day, value: -1, to: now) ?? now,
                icon: "🍕",
                participantsCount: 4,
                balanceDelta: 12
            ),
            Event(
                name: "Такси",
                positions: [],
                date: calendar.date(byAdding: .day, value: -3, to: now) ?? now,
                icon: "🚕",
                participantsCount: 2,
                balanceDelta: -18
            ),
            Event(
                name: "Амстердам",
                positions: [],
                date: calendar.date(byAdding: .day, value: -14, to: now) ?? now,
                icon: "🏖️",
                participantsCount: 6,
                balanceDelta: 0
            )
        ]
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
