import SwiftUI
import Combine

@MainActor
class BillViewModel: ObservableObject {
    @Published var items: [BillItem] = []
    @Published var participants: [Participant] = []
    @Published var selectedItemForAssignment: BillItem?

    var total: Decimal {
        items.reduce(0) { $0 + $1.amount }
    }

    init() {
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
        let newItem = BillItem(name: "", amount: 0, isEditing: true)
        var transaction = Transaction()
        transaction.animation = nil

        withTransaction(transaction) {
            items.append(newItem)
        }

        // Mark insertion animation as completed so it doesn't replay.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) { [weak self] in
            self?.finishInsertAnimation(for: newItem.id)
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

    private func finishInsertAnimation(for id: UUID) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        items[index].isEditing = false
    }
}
