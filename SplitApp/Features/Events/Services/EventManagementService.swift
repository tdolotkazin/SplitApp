import Foundation

protocol EventManagementServiceProtocol {
    func fetchHomeData() async throws -> EventsHomeData
    func fetchReceipts(eventId: UUID) async throws -> [ReceiptDTO]
    func createReceipt(eventId: UUID, request: CreateReceiptRequest) async throws -> ReceiptDTO
    func updateReceipt(id: UUID, request: UpdateReceiptRequest) async throws -> ReceiptDTO
    func fetchEvent(id: UUID) async throws -> Event
    func cachedEvent(id: UUID) async throws -> Event?
    func refreshEvent(id: UUID) async throws -> Event
}

struct EventManagementService: EventManagementServiceProtocol {

    private let eventsRepository: EventsRepositoryProtocol
    private let receiptsRepository: ReceiptsRepositoryProtocol

    init(
        eventsRepository: EventsRepositoryProtocol = EventsRepository(),
        receiptsRepository: ReceiptsRepositoryProtocol = ReceiptsRepository()
    ) {
        self.eventsRepository = eventsRepository
        self.receiptsRepository = receiptsRepository
    }

    func fetchHomeData() async throws -> EventsHomeData {
        let events = try await eventsRepository.listEvents(userId: nil)

        let balanceSummary = EventBalanceSummary(
            totalBalance: 34,
            owedToYou: 18,
            youOwe: 12
        )

        return EventsHomeData(
            balanceSummary: balanceSummary,
            events: events
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
    func fetchEvent(id: UUID) async throws -> Event {
        try await eventsRepository.getEvent(id: id)
    }

    func cachedEvent(id: UUID) async throws -> Event? {
        try await eventsRepository.getCachedEvent(id: id)
    }

    func refreshEvent(id: UUID) async throws -> Event {
        try await eventsRepository.refreshEvent(id: id)
    }

    func createEvent(name: String) async throws -> EventListItem {
        let creatorId = CurrentUserStore.shared.user.id
        let request = CreateEventRequest(creatorId: creatorId, name: name)
        let event = try await eventsRepository.createEvent(request)
        return EventMapper.mapToListItem(event)
    }

    func deleteEvent(id: UUID) async throws {
        try await eventsRepository.deleteEvent(id: id)
    }
}
