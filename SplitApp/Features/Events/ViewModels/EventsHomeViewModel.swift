import Foundation
import Combine

@MainActor
final class EventsHomeViewModel: ObservableObject {
    @Published private(set) var balanceSummary: EventBalanceSummary
    @Published private(set) var latestEvents: [EventListItem]
    @Published private(set) var isLoaded = false

    private let service: EventManagementServiceProtocol

    init(service: EventManagementServiceProtocol) {
        self.service = service
        self.balanceSummary = EventBalanceSummary(totalBalance: 0, owedToYou: 0, youOwe: 0)
        self.latestEvents = []
    }

    func loadDataIfNeeded() async {
        guard !isLoaded else { return }
        isLoaded = true

        let homeData = await service.fetchHomeData()
        balanceSummary = homeData.balanceSummary
        latestEvents = homeData.events.map(Self.mapEventToListItem)
    }

    private static func mapEventToListItem(_ event: Event) -> EventListItem {
        EventListItem(
            emoji: event.icon,
            title: event.name,
            subtitle: "\(event.participantsCount) уч. · \(relativeDateText(from: event.date))",
            amount: event.balanceDelta,
            tone: tone(for: event.balanceDelta)
        )
    }

    private static func tone(for amount: Double) -> EventAmountTone {
        if amount > 0 { return .positive }
        if amount < 0 { return .negative }
        return .neutral
    }

    private static func relativeDateText(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

extension EventsHomeViewModel {
    static func mock(service: EventManagementServiceProtocol = EventManagementService()) -> EventsHomeViewModel {
        let viewModel = EventsHomeViewModel(service: service)
        Task { await viewModel.loadDataIfNeeded() }
        return viewModel
    }
}
