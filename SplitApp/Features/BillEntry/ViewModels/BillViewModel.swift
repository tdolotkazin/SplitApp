import Combine
import SwiftUI

@MainActor
final class BillViewModel: ObservableObject {
    enum Mode {
        case create(eventId: UUID?, scannedItems: [BillItem])
        case edit(eventId: UUID, receiptId: UUID)

        var eventId: UUID? {
            switch self {
            case .create(let eventId, _):
                return eventId
            case .edit(let eventId, _):
                return eventId
            }
        }
    }

    @Published var items: [BillItem] = []
    @Published var participants: [Participant] = []
    @Published var isAddingItem = false
    @Published var selectedItemForAssignment: BillItem?
    @Published var receiptTitle = ""
    @Published var isLoading = false
    @Published var showParticipantPicker = false
    @Published var triggerAnimation = UUID()
    @Published private(set) var isSaving = false
    @Published var isUsingCachedData = false
    @Published private(set) var isNetworkAvailable: Bool
    @Published var loadErrorMessage: String?
    @Published var saveErrorMessage: String?

    let mode: Mode
    let eventsRepository: any EventsRepository
    let receiptsRepository: any ReceiptsRepository
    private let networkMonitor: NetworkMonitor

    private var cancellables: Set<AnyCancellable> = []
    private var hasLoaded = false

    var loadedEvent: Event?
    var loadedReceipt: Receipt?
    var payerId: UUID?

    var total: Decimal {
        items.reduce(0) { $0 + $1.amount }
    }

    @MainActor
    init(service: EventManagementServiceProtocol? = nil) {
        self.service = service ?? EventManagementService()

        // Получаем участников из локального хранилища и преобразуем в Participant
        let users = LocalEventStore.shared.getCurrentParticipants()
        let colors: [String] = [
            "#7C3AED", "#06B6D4", "#3B82F6", "#F59E0B", "#10B981", "#EF4444",
            "#8B5CF6", "#EC4899", "#14B8A6", "#F97316", "#6366F1", "#D946EF",
            "#0EA5E9", "#84CC16", "#F43F5E", "#A78BFA", "#2DD4BF", "#FB923C",
            "#4ADE80", "#E879F9"
        ]
    }

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
    var title: String {
        switch mode {
        case .create:
            return "Ввод чека"
        case .edit:
            return "Чек"
        }
    }

    var statusMessage: String? {
        if let saveErrorMessage {
            return saveErrorMessage
        }
        if let loadErrorMessage, !items.isEmpty {
            return loadErrorMessage
        }
        if let saveDisabledReason {
            return saveDisabledReason
        }
        if isUsingCachedData {
            return "Показываем сохранённый чек. Для сохранения изменений нужен интернет."
        }
        return nil
    }

    var canSave: Bool {
        !isLoading && !isSaving && saveDisabledReason == nil
    }

    var saveButtonTitle: String {
        isSaving ? "Сохраняем..." : "Разделить счёт"
    }

    private var saveDisabledReason: String? {
        switch mode {
        case .create(let eventId, _) where eventId == nil:
            return "Сохранение доступно только внутри события."
        default:
            break
        }

        if !isNetworkAvailable {
            return "Без интернета сохранение пока недоступно."
        }

        return nil
    }

    init(
        mode: Mode,
        eventsRepository: any EventsRepository,
        receiptsRepository: any ReceiptsRepository,
        networkMonitor: NetworkMonitor
    ) {
        self.mode = mode
        self.eventsRepository = eventsRepository
        self.receiptsRepository = receiptsRepository
        self.networkMonitor = networkMonitor
        self.isNetworkAvailable = networkMonitor.isConnected

        if case .create(_, let scannedItems) = mode {
            items = scannedItems
        }

        networkMonitor.$isConnected
            .receive(on: RunLoop.main)
            .sink { [weak self] isConnected in
                self?.isNetworkAvailable = isConnected
            }
            .store(in: &cancellables)
    }

    func load() async {
        guard !hasLoaded else { return }
        hasLoaded = true
        await reload()
    }

    func reload() async {
        loadErrorMessage = nil
        saveErrorMessage = nil

        switch mode {
        case .create(let eventId, let scannedItems):
            await loadCreateContext(eventId: eventId, scannedItems: scannedItems)
        case .edit(let eventId, let receiptId):
            await loadEditContext(eventId: eventId, receiptId: receiptId)
        }
    }

    func addItem() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            let newItem = BillItem(name: "", amount: 0, isEditing: true)
            items.append(newItem)
            isAddingItem = true
            triggerAnimation = UUID()
        }

        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }

    func removeItem(id: UUID) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            items.removeAll { $0.id == id }
        }

        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
    }

    func updateItem(
        id: UUID,
        name: String? = nil,
        amount: Decimal? = nil,
        assignedTo: [Participant]? = nil
    ) {
        guard let index = items.firstIndex(where: { $0.id == id }) else {
            return
        }

        if let name {
            items[index].name = name
        }
        if let amount {
            items[index].amount = amount
        }
        if let assignedTo {
            items[index].assignedTo = assignedTo
        }
    }

    func assignParticipant(to itemId: UUID, participant: Participant) {
        guard let index = items.firstIndex(where: { $0.id == itemId }) else {
            return
        }

        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            items[index].assignedTo = [participant]
        }

        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    func toggleParticipant(to itemId: UUID, participant: Participant) {
        guard let index = items.firstIndex(where: { $0.id == itemId }) else {
            return
        }

        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            if items[index].assignedTo.contains(where: { $0.id == participant.id }) {
                items[index].assignedTo.removeAll { $0.id == participant.id }
            } else {
                items[index].assignedTo.append(participant)
            }
        }

        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    func save() async -> Bool {
        saveErrorMessage = nil

        guard let eventId = mode.eventId else {
            saveErrorMessage = "Нужно открыть счёт из события, чтобы сохранить его на сервер."
            return false
        }

        guard canSave else {
            return false
        }

        let validItems = items.filter {
            !$0.name.isEmpty && $0.amount > 0 && !$0.assignedTo.isEmpty
        }
        guard !validItems.isEmpty else {
            saveErrorMessage = "Добавь хотя бы одну заполненную позицию с назначенным участником."
            return false
        }

        guard let payerId = payerId ?? loadedEvent?.creatorId ?? participants.first?.id else {
            saveErrorMessage = "Не удалось определить плательщика для этого чека."
            return false
        }

        let request = makeReceiptRequest(payerId: payerId, items: validItems)

        isSaving = true
        defer { isSaving = false }

        do {
            try await persistReceipt(request, eventId: eventId)
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            return true
        } catch {
            saveErrorMessage = error.localizedDescription
            return false
        }
    }
}
