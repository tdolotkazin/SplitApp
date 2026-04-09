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
    @Published var receiptTitle: String = ""

    private let service: EventManagementServiceProtocol
    var currentEventId: UUID?
    var currentReceiptId: UUID? // ID редактируемого чека
    var onReceiptCreated: (() -> Void)?

    var total: Decimal {
        items.reduce(0) { $0 + $1.amount }
    }

    init(service: EventManagementServiceProtocol = EventManagementService()) {
        self.service = service

        // Получаем участников из локального хранилища и преобразуем в Participant
        let users = LocalEventStore.shared.getCurrentParticipants()
        let colors: [String] = [
            "#7C3AED", "#06B6D4", "#3B82F6", "#F59E0B", "#10B981", "#EF4444",
            "#8B5CF6", "#EC4899", "#14B8A6", "#F97316", "#6366F1", "#D946EF",
            "#0EA5E9", "#84CC16", "#F43F5E", "#A78BFA", "#2DD4BF", "#FB923C",
            "#4ADE80", "#E879F9"
        ]

        participants = users.enumerated().map { index, user in
            let colorHex = colors[index % colors.count]
            let initials = String(user.name.prefix(2)).uppercased()

            return Participant(
                id: user.id,
                name: user.name,
                initials: initials,
                color: Color(hex: colorHex)
            )
        }

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

        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        Task {
            do {
                // Проверяем, редактируем ли мы существующий чек или создаём новый
                if let receiptId = currentReceiptId {
                    // Обновляем существующий чек
                    let request = createUpdateReceiptRequest(from: validItems)
                    print("🔵 Обновляем чек: \(receiptId)")
                    let receipt = try await service.updateReceipt(id: receiptId, request: request)
                    print("✅ Чек успешно обновлён! ID: \(receipt.id)")
                } else {
                    // Создаём новый чек
                    let eventId = currentEventId ?? LocalEventStore.shared.currentEventId
                    guard let eventId = eventId else {
                        print("Нет текущего события")
                        return
                    }

                    let request = createReceiptRequest(from: validItems)
                    print("🔵 Создаем чек для события: \(eventId)")
                    let receipt = try await service.createReceipt(eventId: eventId, request: request)
                    print("✅ Чек успешно создан! ID: \(receipt.id), eventId: \(receipt.eventId)")
                }
                onReceiptCreated?()
            } catch {
                print("❌ Ошибка сохранения чека: \(error)")
            }
        }
    }

    private func createReceiptRequest(from items: [BillItem]) -> CreateReceiptRequest {
        // Используем первого участника как плательщика (payer)
        let payerId = LocalEventStore.shared.getDefaultPayerId()

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
            title: receiptTitle.isEmpty ? nil : receiptTitle,
            totalAmount: NSDecimalNumber(decimal: total).doubleValue,
            items: requestItems
        )
    }

    private func createUpdateReceiptRequest(from items: [BillItem]) -> UpdateReceiptRequest {
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

        return UpdateReceiptRequest(
            title: receiptTitle.isEmpty ? nil : receiptTitle,
            totalAmount: NSDecimalNumber(decimal: total).doubleValue,
            items: requestItems
        )
    }

    func loadReceipt(_ receipt: ReceiptDTO) {
        print("📝 Загружаем чек для редактирования: \(receipt.id)")

        currentReceiptId = receipt.id
        receiptTitle = receipt.title ?? ""

        // Преобразуем ReceiptItemDTO в BillItem
        items = receipt.items.map { receiptItem in
            // Находим участников по их ID
            let assignedParticipants = participants.filter { participant in
                receiptItem.shareItems.contains(participant.id)
            }

            return BillItem(
                id: receiptItem.id,
                name: receiptItem.name ?? "",
                amount: Decimal(receiptItem.cost),
                assignedTo: assignedParticipants
            )
        }

        print("📝 Загружено позиций: \(items.count), название: \(receiptTitle)")
    }
}
