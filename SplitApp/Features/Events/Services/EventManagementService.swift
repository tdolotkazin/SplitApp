import Foundation
import SwiftUI

protocol EventManagementServiceProtocol {
    func fetchHomeData() async throws -> EventsHomeData
    func fetchReceipts(eventId: UUID) async throws -> [ReceiptDTO]
    func createReceipt(eventId: UUID, request: CreateReceiptRequest) async throws -> ReceiptDTO
    func updateReceipt(id: UUID, request: UpdateReceiptRequest) async throws -> ReceiptDTO
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
    }
}
