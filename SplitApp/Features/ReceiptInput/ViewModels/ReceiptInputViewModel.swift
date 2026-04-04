import Foundation
import Combine

@MainActor
final class ReceiptInputViewModel: ObservableObject {
    @Published private(set) var lineItems: [ReceiptLineItem] = []
    @Published private(set) var participants: [ReceiptParticipant] = []
    @Published private(set) var isLoaded = false

    private let service: EventManagementServiceProtocol
    private var initialLineItems: [ReceiptLineItem] = []
    private var amountInputs: [UUID: String] = [:]

    init(service: EventManagementServiceProtocol) {
        self.service = service
    }

    func loadDraftIfNeeded() async {
        guard !isLoaded else { return }
        isLoaded = true
        await reloadDraft()
    }

    func resetDraft() {
        lineItems = initialLineItems
        rebuildAmountInputs()
    }

    func populate(from items: [ReceiptItem]) {
        guard let defaultParticipant = participants.first else { return }
        lineItems = items.map {
            ReceiptLineItem(
                title: $0.name,
                amount: (NSDecimalNumber(decimal: $0.amount)).doubleValue,
                participant: defaultParticipant
            )
        }
        rebuildAmountInputs()
    }

    var totalAmount: Double {
        lineItems.reduce(0) { $0 + $1.amount }
    }

    func addPosition() {
        guard let participant = participants.first else { return }

        let newItem = ReceiptLineItem(
            title: "Новая позиция",
            amount: 0,
            participant: participant
        )
        lineItems.append(newItem)
        amountInputs[newItem.id] = "0"
    }

    func updateTitle(_ title: String, at index: Int) {
        guard lineItems.indices.contains(index) else { return }
        lineItems[index].title = title
    }

    func updateAmountInput(_ input: String, at index: Int) {
        guard lineItems.indices.contains(index) else { return }

        let itemID = lineItems[index].id
        amountInputs[itemID] = input

        let normalized = input.replacingOccurrences(of: ",", with: ".")
        lineItems[index].amount = Double(normalized) ?? 0
    }

    func setParticipant(_ participant: ReceiptParticipant, at index: Int) {
        guard lineItems.indices.contains(index) else { return }
        lineItems[index].participant = participant
    }

    func amountInput(for itemID: UUID) -> String {
        amountInputs[itemID] ?? Self.amountText(from: lineItems.first(where: { $0.id == itemID })?.amount ?? 0)
    }

    private func reloadDraft() async {
        let draft = await service.fetchReceiptDraft()
        participants = draft.participants
        lineItems = draft.lineItems
        initialLineItems = draft.lineItems
        rebuildAmountInputs()
    }

    private func rebuildAmountInputs() {
        amountInputs = Dictionary(
            uniqueKeysWithValues: lineItems.map { item in
                (item.id, Self.amountText(from: item.amount))
            }
        )
    }

    private static func amountText(from amount: Double) -> String {
        if amount.rounded() == amount {
            return String(Int(amount))
        }

        return String(format: "%.2f", amount).replacingOccurrences(of: ".", with: ",")
    }
}

extension ReceiptInputViewModel {
    @MainActor static func mock(
        service: EventManagementServiceProtocol = EventManagementService()
    ) -> ReceiptInputViewModel {
        let viewModel = ReceiptInputViewModel(service: service)
        Task { await viewModel.loadDraftIfNeeded() }
        return viewModel
    }
}
