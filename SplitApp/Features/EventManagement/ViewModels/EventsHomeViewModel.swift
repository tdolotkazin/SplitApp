import Foundation
import Combine

@MainActor
final class EventsHomeViewModel: ObservableObject {
    @Published private(set) var balanceSummary: EventBalanceSummary
    @Published private(set) var latestEvents: [EventListItem]

    init(balanceSummary: EventBalanceSummary, latestEvents: [EventListItem]) {
        self.balanceSummary = balanceSummary
        self.latestEvents = latestEvents
    }

    convenience init(service: EventManagementServiceProtocol) {
        let homeData = service.fetchHomeData()
        let listItems = homeData.events.map(Self.mapEventToListItem)

        self.init(
            balanceSummary: homeData.balanceSummary,
            latestEvents: listItems
        )
    }

    private static func mapEventToListItem(_ event: Event) -> EventListItem {
        EventListItem(
            emoji: event.icon,
            title: event.name,
            subtitle: "\(event.participantsCount) уч. · \(event.relativeDateText)",
            amount: event.balanceDelta ?? 0,
            tone: tone(for: event.balanceDelta)
        )
    }

    private static func tone(for amount: Double?) -> EventAmountTone {
        guard let amount else { return .neutral }
        if amount > 0 { return .positive }
        if amount < 0 { return .negative }
        return .neutral
    }
}

extension EventsHomeViewModel {
    static func mock(service: EventManagementServiceProtocol = MockEventManagementService()) -> EventsHomeViewModel {
        EventsHomeViewModel(service: service)
    }
}
