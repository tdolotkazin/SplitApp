import Foundation
import SwiftUI

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

    func fetchReceiptDraft() async -> ReceiptDraft {
        let participants = [
            ReceiptParticipant(name: "Вы", color: .accentColor),
            ReceiptParticipant(name: "Гость", color: .orange)
        ]
        return ReceiptDraft(participants: participants, lineItems: [])
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
}
