import Foundation
import Combine

@MainActor
final class ReceiptInputViewModel: ObservableObject {
    @Published private(set) var lineItems: [ReceiptLineItem]
    let participants: [ReceiptParticipant]

    private let initialLineItems: [ReceiptLineItem]

    init(lineItems: [ReceiptLineItem], participants: [ReceiptParticipant]) {
        self.lineItems = lineItems
        self.participants = participants
        self.initialLineItems = lineItems
    }

    convenience init(service: EventManagementServiceProtocol) {
        let draft = service.fetchReceiptDraft()
        self.init(lineItems: draft.lineItems, participants: draft.participants)
    }

    var totalAmount: Double {
        lineItems
            .filter { !$0.isPlaceholder }
            .reduce(0) { $0 + $1.amount }
    }

    func addPosition() {
        if let placeholderIndex = lineItems.firstIndex(where: { $0.isPlaceholder }) {
            lineItems[placeholderIndex].isPlaceholder = false
            lineItems[placeholderIndex].participant = lineItems[placeholderIndex].participant ?? participants.first

            if lineItems[placeholderIndex].title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                lineItems[placeholderIndex].title = "Новая позиция"
            }

            if lineItems[placeholderIndex].amountInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                lineItems[placeholderIndex].amountInput = "0"
                lineItems[placeholderIndex].amount = 0
            }
        } else {
            lineItems.append(
                ReceiptLineItem(
                    title: "Новая позиция",
                    amount: 0,
                    participant: participants.first,
                    isPlaceholder: false
                )
            )
        }

        appendPlaceholderIfNeeded()
    }

    func setParticipant(_ participant: ReceiptParticipant?, for itemID: UUID) {
        guard let index = lineItems.firstIndex(where: { $0.id == itemID }) else { return }
        lineItems[index].participant = participant
        promoteFromPlaceholderIfNeeded(at: index)
    }

    func updateTitle(_ title: String, for itemID: UUID) {
        guard let index = lineItems.firstIndex(where: { $0.id == itemID }) else { return }
        lineItems[index].title = title
        promoteFromPlaceholderIfNeeded(at: index)
    }

    func updateAmountInput(_ input: String, for itemID: UUID) {
        guard let index = lineItems.firstIndex(where: { $0.id == itemID }) else { return }
        lineItems[index].amountInput = input

        let normalized = input.replacingOccurrences(of: ",", with: ".")
        if normalized.isEmpty {
            lineItems[index].amount = 0
        } else if let parsed = Double(normalized) {
            lineItems[index].amount = parsed
        }

        promoteFromPlaceholderIfNeeded(at: index)
    }

    func resetDraft() {
        lineItems = initialLineItems
    }

    private func appendPlaceholderIfNeeded() {
        guard !lineItems.contains(where: { $0.isPlaceholder }) else { return }

        lineItems.append(
            ReceiptLineItem(
                title: "Десерт",
                amount: 0,
                participant: nil,
                isPlaceholder: true
            )
        )
    }

    private func promoteFromPlaceholderIfNeeded(at index: Int) {
        guard lineItems[index].isPlaceholder else { return }

        let hasMeaningfulTitle = !lineItems[index].title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasAmount = lineItems[index].amount > 0
        let hasParticipant = lineItems[index].participant != nil

        if hasMeaningfulTitle || hasAmount || hasParticipant {
            lineItems[index].isPlaceholder = false
        }
    }
}

extension ReceiptInputViewModel {
    static func mock(service: EventManagementServiceProtocol = MockEventManagementService()) -> ReceiptInputViewModel {
        ReceiptInputViewModel(service: service)
    }
}
