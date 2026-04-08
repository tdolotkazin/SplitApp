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
    @Published var showParticipantPicker = false
    @Published var triggerAnimation = UUID()
    @Published private(set) var isLoading = false
    @Published private(set) var isSaving = false
    @Published private(set) var isUsingCachedData = false
    @Published private(set) var isNetworkAvailable: Bool
    @Published private(set) var loadErrorMessage: String?
    @Published private(set) var saveErrorMessage: String?

    private let mode: Mode
    private let eventsRepository: EventsRepositoryProtocol
    private let receiptsRepository: ReceiptsRepositoryProtocol
    private let networkMonitor: NetworkMonitor
    private var cancellables: Set<AnyCancellable> = []
    private var hasLoaded = false
    private var loadedEvent: Event?
    private var loadedReceipt: Receipt?
    private var payerId: UUID?

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
            return
                "Показываем сохранённый чек. Для сохранения изменений нужен интернет."
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
        eventsRepository: EventsRepositoryProtocol = EventsRepository(),
        receiptsRepository: ReceiptsRepositoryProtocol = ReceiptsRepository(),
        networkMonitor: NetworkMonitor = .shared
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
            await loadCreateContext(
                eventId: eventId,
                scannedItems: scannedItems
            )
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
            saveErrorMessage =
                "Нужно открыть счёт из события, чтобы сохранить его на сервер."
            return false
        }

        guard canSave else {
            return false
        }

        let validItems = items.filter {
            !$0.name.isEmpty && $0.amount > 0 && !$0.assignedTo.isEmpty
        }
        guard !validItems.isEmpty else {
            saveErrorMessage =
                "Добавь хотя бы одну заполненную позицию с назначенным участником."
            return false
        }

        guard
            let payerId = payerId ?? loadedEvent?.creatorId
                ?? participants.first?.id
        else {
            saveErrorMessage =
                "Не удалось определить плательщика для этого чека."
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

private extension BillViewModel {
    func loadCreateContext(eventId: UUID?, scannedItems: [BillItem]) async {
        if items.isEmpty {
            items = scannedItems
        }

        guard let eventId else {
            participants = [
                Participant(name: "Я", initials: "Я", color: .accentColor),
                Participant(name: "Друг 1", initials: "Д1", color: .blue),
                Participant(name: "Друг 2", initials: "Д2", color: .green)
            ]
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
        isLoading = participants.isEmpty

        if let cachedEvent = try? await eventsRepository.getCachedEvent(
            id: eventId
        ) {
            apply(event: cachedEvent)
            isLoading = false
        }

        do {
            let refreshedEvent = try await eventsRepository.refreshEvent(
                id: eventId
            )
            apply(event: refreshedEvent)
        } catch {
            if loadedEvent == nil {
                loadErrorMessage = error.localizedDescription
            }
        }

        isLoading = false
    }

    func loadEditContext(eventId: UUID, receiptId: UUID) async {
        isLoading = items.isEmpty
        isUsingCachedData = false

        if let cachedEvent = try? await eventsRepository.getCachedEvent(
            id: eventId
        ) {
            apply(event: cachedEvent)
            isLoading = false
        }

        if let cachedReceipt = try? await receiptsRepository.getCachedReceipt(
            id: receiptId
        ) {
            apply(receipt: cachedReceipt)
            isUsingCachedData = true
            isLoading = false
        }

        do {
            async let refreshedEvent = eventsRepository.refreshEvent(
                id: eventId
            )
            async let refreshedReceipts = receiptsRepository.refreshReceipts(
                eventId: eventId
            )

            let event = try await refreshedEvent
            let receipts = try await refreshedReceipts
            apply(event: event)

            guard let receipt = receipts.first(where: { $0.id == receiptId })
            else {
                if loadedReceipt == nil {
                    loadErrorMessage = "Чек больше не доступен."
                }
                isLoading = false
                return
            }

            apply(receipt: receipt)
            isUsingCachedData = false
        } catch {
            if loadedReceipt == nil {
                loadErrorMessage = error.localizedDescription
            } else {
                isUsingCachedData = true
            }
        }

        isLoading = false
    }

    func persistReceipt(
        _ request: CreateReceiptRequest,
        eventId: UUID
    ) async throws {
        switch mode {
        case .create:
            _ = try await receiptsRepository.createReceipt(
                eventId: eventId,
                request
            )
        case .edit(_, let receiptId):
            _ = try await receiptsRepository.updateReceipt(
                id: receiptId,
                UpdateReceiptRequest(
                    title: request.title,
                    totalAmount: request.totalAmount,
                    items: request.items
                )
            )
        }
    }

    func apply(event: Event) {
        loadedEvent = event
        payerId = loadedReceipt?.payerId ?? event.creatorId
        participants = event.participants.map(Self.makeParticipant)

        if let loadedReceipt {
            items = mapReceiptToBillItems(
                loadedReceipt,
                participants: participants
            )
        }
    }

    func apply(receipt: Receipt) {
        loadedReceipt = receipt
        payerId = receipt.payerId
        items = mapReceiptToBillItems(receipt, participants: participants)
    }

    func mapReceiptToBillItems(
        _ receipt: Receipt,
        participants: [Participant]
    ) -> [BillItem] {
        receipt.items.map { item in
            let assignedParticipant = item.shares.first.flatMap { share in
                participants.first(where: { $0.id == share.userId })
            }

            return BillItem(
                id: item.id,
                name: item.name,
                amount: Decimal(item.cost),
                assignedTo: assignedParticipant
            )
        }
    }

    func makeReceiptRequest(
        payerId: UUID,
        items: [BillItem]
    ) -> CreateReceiptRequest {
        CreateReceiptRequest(
            payerId: payerId,
            title: nil,
            totalAmount: NSDecimalNumber(decimal: total).doubleValue,
            items: items.compactMap { item in
                guard let assignedTo = item.assignedTo else { return nil }

                return CreateReceiptItemRequest(
                    name: item.name.isEmpty ? nil : item.name,
                    cost: NSDecimalNumber(decimal: item.amount).doubleValue,
                    shareItems: [
                        CreateShareItemRequest(
                            userId: assignedTo.id,
                            shareValue: 1
                        )
                    ]
                )
            }
        )
    }

    static func makeParticipant(from user: User) -> Participant {
        Participant(
            id: user.id,
            name: user.name,
            initials: String(user.name.prefix(2)).uppercased(),
            color: .accentColor
        )
    }
}
