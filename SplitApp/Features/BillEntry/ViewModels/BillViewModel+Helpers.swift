import Foundation
import SwiftUI

extension BillViewModel {
    func loadCreateContext(
        eventId: UUID?,
        scannedItems: [BillItem],
        receiptImageJPEGData: Data?
    ) async {
        if items.isEmpty {
            items = scannedItems
        }
        if self.receiptImageJPEGData == nil {
            self.receiptImageJPEGData = receiptImageJPEGData
        }

        guard let eventId else {
            await loadFriendsIntoParticipants()

            if participants.isEmpty {
                participants = [
                    Participant(name: "Я", initials: "Я", color: .accentColor),
                    Participant(name: "Друг 1", initials: "Д1", color: .blue),
                    Participant(name: "Друг 2", initials: "Д2", color: .green)
                ]
            }
            return
        }

        isLoading = participants.isEmpty

        if let cachedEvent = try? await eventsRepository.getCachedEvent(
            id: eventId
        ) {
            apply(event: cachedEvent)
            await loadParticipantsFromBackendIfNeeded(for: cachedEvent)
            isLoading = false
        }

        do {
            let refreshedEvent = try await eventsRepository.refreshEvent(
                id: eventId
            )
            apply(event: refreshedEvent)
            await loadParticipantsFromBackendIfNeeded(for: refreshedEvent)
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
            await loadParticipantsFromBackendIfNeeded(for: cachedEvent)
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
            await loadParticipantsFromBackendIfNeeded(for: event)

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
        _ command: CreateReceiptCommand,
        eventId: UUID
    ) async throws {
        switch mode {
        case .create:
            _ = try await receiptsRepository.createReceipt(
                eventId: eventId,
                command
            )
        case .edit(_, let receiptId):
            _ = try await receiptsRepository.updateReceipt(
                id: receiptId,
                UpdateReceiptCommand(
                    title: command.title,
                    totalAmount: command.totalAmount,
                    items: command.items
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
        receiptTitle = receipt.title ?? ""
        items = mapReceiptToBillItems(receipt, participants: participants)
    }

    func mapReceiptToBillItems(
        _ receipt: Receipt,
        participants: [Participant]
    ) -> [BillItem] {
        receipt.items.map { item in
            let assignedParticipants = item.shares.compactMap { share in
                participants.first(where: { $0.id == share.userId })
            }

            return BillItem(
                id: item.id,
                name: item.name,
                amount: Decimal(item.cost),
                assignedTo: assignedParticipants
            )
        }
    }

    func makeReceiptRequest(
        payerId: UUID,
        items: [BillItem]
    ) -> CreateReceiptCommand {
        let trimmedTitle = receiptTitle.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        return CreateReceiptCommand(
            payerId: payerId,
            title: trimmedTitle.isEmpty ? nil : trimmedTitle,
            totalAmount: NSDecimalNumber(decimal: total).doubleValue,
            items: items.compactMap { item in
                guard !item.assignedTo.isEmpty else { return nil }

                return CreateReceiptItemCommand(
                    name: item.name.isEmpty ? nil : item.name,
                    cost: NSDecimalNumber(decimal: item.amount).doubleValue,
                    shareItems: zip(
                        item.assignedTo,
                        normalizedShareValues(for: item.assignedTo.count)
                    ).map { assignedTo, shareValue in
                        CreateShareItemCommand(
                            userId: assignedTo.id,
                            shareValue: shareValue
                        )
                    }
                )
            },
            receiptImageJPEGData: receiptImageJPEGData
        )
    }

    func normalizedShareValues(for participantCount: Int) -> [Double] {
        guard participantCount > 0 else { return [] }
        guard participantCount > 1 else { return [1] }

        let scale = 1_000_000
        let baseScaled = scale / participantCount
        let lastScaled = scale - baseScaled * (participantCount - 1)

        var values = Array(
            repeating: Double(baseScaled) / Double(scale),
            count: participantCount
        )
        values[participantCount - 1] = Double(lastScaled) / Double(scale)
        return values
    }

    static func makeParticipant(from user: User) -> Participant {
        Participant(
            id: user.id,
            name: user.name,
            initials: String(user.name.prefix(2)).uppercased(),
            color: .accentColor
        )
    }

    func loadParticipantsFromBackendIfNeeded(for event: Event) async {
        let eventParticipants = (event.participants + event.users).map(Self.makeParticipant)
        participants = mergeParticipants(eventParticipants)
        print("[BillParticipants] mode=event_only eventId=\(event.id) count=\(participants.count)")

        if let loadedReceipt {
            items = mapReceiptToBillItems(loadedReceipt, participants: participants)
        }
    }

    func loadFriendsIntoParticipants() async {
        do {
            let users = try await usersRepository.listUsers()
            participants = mergeParticipants(users.map(Self.makeParticipant))
        } catch {
            do {
                let cachedUsers = try await usersRepository.getCachedUsers()
                participants = mergeParticipants(cachedUsers.map(Self.makeParticipant))
            } catch {
                participants = mergeParticipants([])
            }
        }
    }

    func mergeParticipants(_ newParticipants: [Participant]) -> [Participant] {
        var byId: [UUID: Participant] = [:]

        for participant in participants {
            byId[participant.id] = participant
        }

        for participant in newParticipants {
            byId[participant.id] = participant
        }

        return byId.values.sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
    }
}
