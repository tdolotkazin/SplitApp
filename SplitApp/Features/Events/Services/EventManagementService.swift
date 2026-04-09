import Foundation

protocol EventManagementServiceProtocol {
    func fetchHomeData() async throws -> EventsHomeData
    func fetchReceipts(eventId: UUID) async throws -> [ReceiptDTO]
    func createReceipt(eventId: UUID, request: CreateReceiptRequest) async throws -> ReceiptDTO
    func updateReceipt(id: UUID, request: UpdateReceiptRequest) async throws -> ReceiptDTO
    func createEvent(name: String) async throws -> Event
    func deleteEvent(id: UUID) async throws
}

struct EventManagementService: EventManagementServiceProtocol {

    private let eventsRepository: any EventsRepository
    private let receiptsRepository: ReceiptsDataRepository
    private let balancesRepository: any BalancesRepository

    init(
        eventsRepository: any EventsRepository = EventsDataRepository(),
        receiptsRepository: ReceiptsDataRepository = ReceiptsDataRepository(),
        balancesRepository: any BalancesRepository = BalancesDataRepository()
    ) {
        self.eventsRepository = eventsRepository
        self.receiptsRepository = receiptsRepository
        self.balancesRepository = balancesRepository
    }

    func fetchHomeData() async throws -> EventsHomeData {
        let events = try await eventsRepository.listEvents(userId: nil)

        let balanceSummary = await calculateBalanceSummary(for: events)

        return EventsHomeData(
            balanceSummary: balanceSummary,
            events: events
        )
    }

    private func calculateBalanceSummary(for events: [Event]) async -> EventBalanceSummary {
        let currentUserId = CurrentUserStore.shared.user.id
        var owedToYou: Double = 0
        var youOwe: Double = 0

        await withTaskGroup(of: [EventBalance].self) { group in
            for event in events {
                group.addTask {
                    (try? await balancesRepository.getEventBalances(eventId: event.id)) ?? []
                }
            }
            for await balances in group {
                for balance in balances {
                    if balance.creditorId == currentUserId {
                        owedToYou += balance.amount
                    } else if balance.debitorId == currentUserId {
                        youOwe += balance.amount
                    }
                }
            }
        }

        return EventBalanceSummary(
            totalBalance: owedToYou - youOwe,
            owedToYou: owedToYou,
            youOwe: youOwe
        )
    }

    func fetchReceipts(eventId: UUID) async throws -> [ReceiptDTO] {
        return try await receiptsRepository.listReceipts(eventId: eventId)
    }

    func createReceipt(eventId: UUID, request: CreateReceiptRequest) async throws -> ReceiptDTO {
        return try await receiptsRepository.createReceipt(eventId: eventId, request)
    }

    func updateReceipt(id: UUID, request: UpdateReceiptRequest) async throws -> ReceiptDTO {
        return try await receiptsRepository.updateReceipt(id: id, request)
    }

    func createEvent(name: String) async throws -> Event {
        let command = CreateEventCommand(name: name)
        return try await eventsRepository.createEvent(command)
    }

    func deleteEvent(id: UUID) async throws {
        try await eventsRepository.deleteEvent(id: id)
    }
}
