import Foundation

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
