import Combine
import Foundation
import SwiftUI

@MainActor
final class EventsHomeViewModel: ObservableObject {
    @Published private(set) var balanceSummary: EventBalanceSummary
    @Published private(set) var latestEvents: [EventListItem]
    @Published private(set) var currentEvent: EventListItem?
    @Published private(set) var currentEventBills: [BillListItem]
    @Published private(set) var isLoaded = false
    @Published private(set) var errorMessage: String?
    @Published var isCreatingEvent = false

    private let service: EventManagementServiceProtocol
    private let activeEventRepository: any ActiveEventRepository
    private var currentEventData: Event?
    private var allEvents: [Event] = []
    private let receiptEmojiResolver: ReceiptTitleEmojiResolver

    init(
        service: EventManagementServiceProtocol,
        activeEventRepository: any ActiveEventRepository
    ) {
        self.service = service
        self.activeEventRepository = activeEventRepository
        self.receiptEmojiResolver = .shared
        self.balanceSummary = EventBalanceSummary(totalBalance: 0, owedToYou: 0, youOwe: 0)
        self.latestEvents = []
        self.currentEvent = nil
        self.currentEventBills = []
        self.currentEventData = nil
    }

    convenience init(service: EventManagementServiceProtocol) {
        self.init(
            service: service,
            activeEventRepository: ActiveEventSelectionDataRepository()
        )
    }

    var currentEventReceiptsTotal: Double {
        currentEventBills.reduce(0) { $0 + $1.amount }
    }

    func loadDataIfNeeded() async {
        guard !isLoaded else { return }

        do {
            let homeData = try await service.fetchHomeData()
            balanceSummary = homeData.balanceSummary
            allEvents = homeData.events
            latestEvents = homeData.events.map(Self.mapEventToListItem)
            currentEventBills = []

            if let resolvedEvent = await resolveCurrentEvent(from: homeData.events) {
                applyCurrentEvent(resolvedEvent)
                await loadReceipts(for: resolvedEvent.id)
            } else {
                currentEvent = nil
                currentEventData = nil
            }

            isLoaded = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func createEvent(name: String) async {
        isCreatingEvent = true
        defer { isCreatingEvent = false }
        do {
            let newEvent = try await service.createEvent(name: name)
            let newItem = Self.mapEventToListItem(newEvent)

            // Сразу показываем новый ивент из POST-ответа — не ждём GET
            latestEvents.insert(newItem, at: 0)
            allEvents.insert(newEvent, at: 0)
            applyCurrentEvent(newEvent)
            currentEventBills = []
            await activeEventRepository.setActiveEventId(newEvent.id)

            // Обновляем список с бека отдельно, не бросая ошибку наверх
            if let homeData = try? await service.fetchHomeData() {
                var fetchedEvents = homeData.events
                var fetchedItems = fetchedEvents.map(Self.mapEventToListItem)
                // Если бек ещё не вернул новый ивент — вставляем сами
                if !fetchedEvents.contains(where: { $0.id == newEvent.id }) {
                    fetchedEvents.insert(newEvent, at: 0)
                    fetchedItems.insert(newItem, at: 0)
                }
                allEvents = fetchedEvents
                latestEvents = fetchedItems
                balanceSummary = homeData.balanceSummary
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteEvent(_ item: EventListItem) {
        let isDeletingCurrentEvent = currentEvent?.id == item.id

        withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
            latestEvents.removeAll { $0.id == item.id }
            allEvents.removeAll { $0.id == item.id }
            if isDeletingCurrentEvent, let firstEvent = allEvents.first {
                applyCurrentEvent(firstEvent)
            } else if isDeletingCurrentEvent {
                currentEvent = nil
                currentEventData = nil
                currentEventBills = []
            }
        }

        if isDeletingCurrentEvent, let firstEvent = allEvents.first {
            Task {
                await activeEventRepository.setActiveEventId(firstEvent.id)
                await loadReceipts(for: firstEvent.id)
            }
        } else if isDeletingCurrentEvent {
            Task {
                await activeEventRepository.clearActiveEventId()
            }
        }

        Task {
            try? await service.deleteEvent(id: item.id)
        }
    }

    func selectEvent(_ item: EventListItem) {
        guard let event = allEvents.first(where: { $0.id == item.id }) else { return }
        applyCurrentEvent(event)
        Task {
            await activeEventRepository.setActiveEventId(event.id)
            await loadReceipts(for: event.id)
        }
    }

    func loadReceipts(for eventId: UUID) async {
        do {
            print("🔵 Загружаем чеки для события: \(eventId)")
            let receipts = try await service.fetchReceipts(eventId: eventId)
            print("✅ Загружено чеков: \(receipts.count)")
            currentEventBills = receipts.map(mapReceiptToBillListItem)
            print("✅ Обновлен список чеков: \(currentEventBills.count)")
        } catch {
            print("❌ Ошибка загрузки чеков: \(error)")
            currentEventBills = []
        }
    }

    private static func mapEventToListItem(_ event: Event) -> EventListItem {
        EventListItem(
            id: event.id,
            emoji: event.icon,
            title: event.name,
            subtitle: relativeDateText(from: event.date),
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

    private static func formatTime(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    private func mapReceiptToBillListItem(_ receipt: ReceiptDTO) -> BillListItem {
        // Считаем количество уникальных участников
        let uniqueParticipants = Set(
            receipt.items.flatMap { item in
                item.shareItems.map(\.userId)
            }
        )
        let participantsCount = uniqueParticipants.count

        let timeText = Self.formatTime(from: receipt.createdAt)
        let subtitle = "\(participantsCount) уч. · \(timeText)"
        let displayTitle = normalizedReceiptTitle(receipt.title)

        return BillListItem(
            id: receipt.id,
            emoji: receiptEmojiResolver.emoji(for: displayTitle),
            title: displayTitle,
            subtitle: subtitle,
            amount: receipt.totalAmount,
            tone: Self.tone(for: receipt.totalAmount)
        )
    }

    private func resolveCurrentEvent(from events: [Event]) async -> Event? {
        guard !events.isEmpty else {
            await activeEventRepository.clearActiveEventId()
            return nil
        }

        if let storedEventId = await activeEventRepository.getActiveEventId(),
           let storedEvent = events.first(where: { $0.id == storedEventId }) {
            return storedEvent
        }

        let firstEvent = events[0]
        await activeEventRepository.setActiveEventId(firstEvent.id)
        return firstEvent
    }

    private func applyCurrentEvent(_ event: Event) {
        currentEventData = event
        currentEvent = Self.mapEventToListItem(event)
        LocalEventStore.shared.setCurrentEvent(id: event.id, participants: event.users)
    }

    private func normalizedReceiptTitle(_ title: String?) -> String {
        let trimmedTitle = title?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmedTitle.isEmpty ? "Чек" : trimmedTitle
    }
}

extension EventsHomeViewModel {
    @MainActor static func mock() -> EventsHomeViewModel {
        let service = EventManagementService()
        let viewModel = EventsHomeViewModel(service: service)
        Task { await viewModel.loadDataIfNeeded() }
        return viewModel
    }
}

private struct ReceiptTitleEmojiResolver {
    static let shared = ReceiptTitleEmojiResolver()
    private static let fallbackEmoji = "🧾"

    private let matcher: EmojiAutoReplaceMatcher

    init(parser: EmojiTextParser = EmojiTextParser()) {
        let emojis = (try? parser.parse()) ?? []
        self.matcher = EmojiAutoReplaceMatcher(emojis: emojis)
    }

    func emoji(for title: String) -> String {
        let words = title
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }

        for word in words {
            if let match = matcher.match(for: word) {
                return match.emoji
            }
        }

        return Self.fallbackEmoji
    }
}
