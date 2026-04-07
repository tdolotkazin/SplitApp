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

    var total: Decimal {
        items.reduce(0) { $0 + $1.amount }
    }

    init() {
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

        // Здесь можно добавить сохранение в CoreData или другой persistence layer
        print("Сохранено \(validItems.count) позиций. Итого: €\(total)")

        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
}
