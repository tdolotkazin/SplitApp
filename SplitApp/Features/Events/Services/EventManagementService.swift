import Foundation
import SwiftUI

protocol EventManagementServiceProtocol {
    func fetchHomeData() async throws -> EventsHomeData
}

struct EventManagementService: EventManagementServiceProtocol {

    private let eventsRepository: EventsRepositoryProtocol

    init(eventsRepository: EventsRepositoryProtocol = EventsRepository()) {
        self.eventsRepository = eventsRepository
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
