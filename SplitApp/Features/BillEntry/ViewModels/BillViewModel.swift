import SwiftUI
import Combine

@MainActor
class BillViewModel: ObservableObject {
    @Published var items: [BillItem] = []
    @Published var participants: [Participant] = []
    @Published var isAddingItem: Bool = false
    @Published var selectedItemForAssignment: BillItem?
    @Published var showParticipantPicker: Bool = false
    @Published var triggerAnimation: UUID = UUID()

    private let service: EventManagementServiceProtocol
    var currentEventId: UUID?
    var onReceiptCreated: (() -> Void)?

    var total: Decimal {
        items.reduce(0) { $0 + $1.amount }
    }

    init(service: EventManagementServiceProtocol = EventManagementService()) {
        self.service = service
        participants = [
            Participant(name: "Артём", initials: "АР", color: Color(hex: "#7C3AED")),
            Participant(name: "Маша", initials: "МС", color: Color(hex: "#06B6D4")),
            Participant(name: "Иван", initials: "ИВ", color: Color(hex: "#3B82F6")),
            Participant(name: "Соня", initials: "СО", color: Color(hex: "#F59E0B")),
            Participant(name: "Дима", initials: "ДМ", color: Color(hex: "#10B981")),
            Participant(name: "Катя", initials: "КА", color: Color(hex: "#EF4444")),
            Participant(name: "Никита", initials: "НК", color: Color(hex: "#8B5CF6")),
            Participant(name: "Оля", initials: "ОЛ", color: Color(hex: "#EC4899")),
            Participant(name: "Рома", initials: "РО", color: Color(hex: "#14B8A6")),
            Participant(name: "Лена", initials: "ЛЕ", color: Color(hex: "#F97316")),
            Participant(name: "Андрей", initials: "АН", color: Color(hex: "#6366F1")),
            Participant(name: "Вика", initials: "ВИ", color: Color(hex: "#D946EF")),
            Participant(name: "Серёжа", initials: "СЕ", color: Color(hex: "#0EA5E9")),
            Participant(name: "Настя", initials: "НА", color: Color(hex: "#84CC16")),
            Participant(name: "Гриша", initials: "ГР", color: Color(hex: "#F43F5E")),
            Participant(name: "Юля", initials: "ЮЛ", color: Color(hex: "#A78BFA")),
            Participant(name: "Тимур", initials: "ТИ", color: Color(hex: "#2DD4BF")),
            Participant(name: "Даша", initials: "ДА", color: Color(hex: "#FB923C")),
            Participant(name: "Костя", initials: "КО", color: Color(hex: "#4ADE80")),
            Participant(name: "Ира", initials: "ИР", color: Color(hex: "#E879F9"))
        ]

        let scanned = ScannedReceiptStore.shared.consume()
        if !scanned.isEmpty {
            items = scanned
        }
    }

    func addItem() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            let newItem = BillItem(name: "", amount: 0, isEditing: true)
            items.append(newItem)
            isAddingItem = true
            triggerAnimation = UUID()
        }

        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }

    func removeItem(id: UUID) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            items.removeAll { $0.id == id }
        }

        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
    }

    func updateItem(id: UUID, name: String? = nil, amount: Decimal? = nil) {
        if let index = items.firstIndex(where: { $0.id == id }) {
            if let name = name {
                items[index].name = name
            }
            if let amount = amount {
                items[index].amount = amount
            }
        }
    }

    func toggleParticipant(to itemId: UUID, participant: Participant) {
        if let index = items.firstIndex(where: { $0.id == itemId }) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                if items[index].assignedTo.contains(where: { $0.id == participant.id }) {
                    items[index].assignedTo.removeAll { $0.id == participant.id }
                } else {
                    items[index].assignedTo.append(participant)
                }
            }
            selectedItemForAssignment = items[index]
        }

        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    func save() {
        // Валидация
        let validItems = items.filter { !$0.name.isEmpty && $0.amount > 0 && !$0.assignedTo.isEmpty }

        guard !validItems.isEmpty else {
            print("Нет валидных позиций для сохранения")
            return
        }

        guard let eventId = currentEventId else {
            print("Нет текущего события")
            return
        }

        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        Task {
            do {
                let request = createReceiptRequest(from: validItems)
                _ = try await service.createReceipt(eventId: eventId, request: request)
                print("Чек успешно создан!")
                onReceiptCreated?()
            } catch {
                print("Ошибка создания чека: \(error)")
            }
        }
    }

    private func createReceiptRequest(from items: [BillItem]) -> CreateReceiptRequest {
        // Используем первого участника как плательщика (payer)
        let payerId = participants.first?.id ?? UUID()

        let requestItems = items.compactMap { item -> CreateReceiptItemRequest? in
            guard !item.assignedTo.isEmpty else { return nil }

            // Создаем shareItems для каждого участника позиции
            let shareItems = item.assignedTo.map { participant in
                CreateShareItemRequest(
                    userId: participant.id,
                    shareValue: NSDecimalNumber(decimal: item.amount).doubleValue / Double(item.assignedTo.count)
                )
            }

            return CreateReceiptItemRequest(
                name: item.name,
                cost: NSDecimalNumber(decimal: item.amount).doubleValue,
                shareItems: shareItems
            )
        }

        return CreateReceiptRequest(
            payerId: payerId,
            title: "Чек",
            totalAmount: NSDecimalNumber(decimal: total).doubleValue,
            items: requestItems
        )
    }
}
