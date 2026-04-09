import Foundation
import Combine
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
    private var currentEventData: Event?
    private var allEvents: [Event] = []

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
            allEvents = homeData.events
            latestEvents = homeData.events.map(Self.mapEventToListItem)

            // Выбираем первое событие как текущее
            if let firstEvent = homeData.events.first {
                currentEventData = firstEvent
                currentEvent = Self.mapEventToListItem(firstEvent)

                // Сохраняем участников события в локальное хранилище
                LocalEventStore.shared.setCurrentEvent(id: firstEvent.id, participants: firstEvent.users)

                await loadReceipts(for: firstEvent.id)
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
            let newItem = try await service.createEvent(name: name)
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                let newEvent = Event(
                    id: newItem.id,
                    name: newItem.title,
                    positions: [],
                    date: Date(),
                    icon: "📌",
                    participantsCount: 0,
                    balanceDelta: 0
                )
                latestEvents.append(newItem)
                allEvents.append(newEvent)
            }
            selectEvent(newItem)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteEvent(_ item: EventListItem) {
        withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
            latestEvents.removeAll { $0.id == item.id }
            allEvents.removeAll { $0.id == item.id }
            if currentEvent?.id == item.id {
                currentEvent = latestEvents.first
                if let first = allEvents.first {
                    LocalEventStore.shared.setCurrentEvent(id: first.id, participants: first.users)
                    Task { await loadReceipts(for: first.id) }
                }
            }
        }
        Task {
            try? await service.deleteEvent(id: item.id)
        }
    }

    func selectEvent(_ item: EventListItem) {
        guard let event = allEvents.first(where: { $0.id == item.id }) else { return }
        currentEventData = event
        currentEvent = Self.mapEventToListItem(event)
        LocalEventStore.shared.setCurrentEvent(id: event.id, participants: event.users)
        Task { await loadReceipts(for: event.id) }
    }

    func loadReceipts(for eventId: UUID) async {
        do {
            print("🔵 Загружаем чеки для события: \(eventId)")
            let receipts = try await service.fetchReceipts(eventId: eventId)
            print("✅ Загружено чеков: \(receipts.count)")
            currentEventBills = receipts.map(Self.mapReceiptToBillListItem)
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

    private static func mapReceiptToBillListItem(_ receipt: ReceiptDTO) -> BillListItem {
        print("🔄 Маппинг чека: \(receipt.id), title: \(receipt.title ?? "nil"), items count: \(receipt.items.count)")

        // Считаем количество уникальных участников
        let uniqueParticipants = Set(
            receipt.items.flatMap { item in
                item.shareItems.map(\.userId)
            }
        )
        let participantsCount = uniqueParticipants.count

        print("🔄 Участников: \(participantsCount)")

        let timeText = formatTime(from: receipt.createdAt)
        let subtitle = "\(participantsCount) уч. · \(timeText)"

        let billItem = BillListItem(
            id: receipt.id,
            emoji: "🧾",
            title: receipt.title ?? "Чек",
            subtitle: subtitle,
            amount: receipt.totalAmount,
            tone: tone(for: receipt.totalAmount)
        )

        print("🔄 Создан BillListItem: id=\(billItem.id), title=\(billItem.title), amount=\(billItem.amount)")

        return billItem
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
