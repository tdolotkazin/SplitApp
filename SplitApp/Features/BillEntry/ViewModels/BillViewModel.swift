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
            Participant(name: "Иван", initials: "ИВ", color: Color(hex: "#3B82F6"))
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

    func updateItem(id: UUID, name: String? = nil, amount: Decimal? = nil, assignedTo: Participant? = nil) {
        if let index = items.firstIndex(where: { $0.id == id }) {
            if let name = name {
                items[index].name = name
            }
            if let amount = amount {
                items[index].amount = amount
            }
            if assignedTo != nil {
                items[index].assignedTo = assignedTo
            }
        }
    }

    func assignParticipant(to itemId: UUID, participant: Participant) {
        if let index = items.firstIndex(where: { $0.id == itemId }) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                items[index].assignedTo = participant
            }
        }

        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    func save() {
        // Валидация
        let validItems = items.filter { !$0.name.isEmpty && $0.amount > 0 && $0.assignedTo != nil }

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
            guard let assignedTo = item.assignedTo else { return nil }

            let shareItem = CreateShareItemRequest(
                userId: assignedTo.id,
                shareValue: NSDecimalNumber(decimal: item.amount).doubleValue
            )

            return CreateReceiptItemRequest(
                name: item.name,
                cost: NSDecimalNumber(decimal: item.amount).doubleValue,
                shareItems: [shareItem]
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
