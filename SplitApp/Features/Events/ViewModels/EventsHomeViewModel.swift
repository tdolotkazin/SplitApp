import Foundation
import Combine

@MainActor
final class EventsHomeViewModel: ObservableObject {
    @Published private(set) var balanceSummary: EventBalanceSummary
    @Published private(set) var latestEvents: [EventListItem]
    @Published private(set) var currentEvent: EventListItem?
    @Published private(set) var currentEventBills: [BillListItem]
    @Published private(set) var isLoaded = false
    @Published private(set) var errorMessage: String?

    private let service: EventManagementServiceProtocol
    private var currentEventData: Event?

    init(service: EventManagementServiceProtocol) {
        self.service = service
        self.balanceSummary = EventBalanceSummary(totalBalance: 0, owedToYou: 0, youOwe: 0)
        self.latestEvents = []
        self.currentEvent = nil
        self.currentEventBills = []
        self.currentEventData = nil
    }

    func loadDataIfNeeded() async {
        guard !isLoaded else { return }

        do {
            let homeData = try await service.fetchHomeData()
            balanceSummary = homeData.balanceSummary
            latestEvents = homeData.events.map(Self.mapEventToListItem)

            // Выбираем первое событие как текущее
            if let firstEvent = homeData.events.first {
                currentEventData = firstEvent
                currentEvent = Self.mapEventToListItem(firstEvent)
                currentEventBills = Self.mapEventBills(firstEvent)
            }

            isLoaded = true
        } catch {
            errorMessage = error.localizedDescription
        }
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

    private static func mapEventBills(_ event: Event) -> [BillListItem] {
        return event.positions.map { position in
            mapPositionToBillListItem(position, eventDate: event.date)
        }
    }

    private static func mapPositionToBillListItem(_ position: Position, eventDate: Date) -> BillListItem {
        let participantsCount = position.participants.count
        let timeText = formatTime(from: eventDate)
        let subtitle = "\(participantsCount) уч. · \(timeText)"

        return BillListItem(
            id: position.id,
            emoji: "🧾",
            title: position.name,
            subtitle: subtitle,
            amount: position.amount,
            tone: tone(for: position.amount)
        )
    }

    private static func formatTime(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}
