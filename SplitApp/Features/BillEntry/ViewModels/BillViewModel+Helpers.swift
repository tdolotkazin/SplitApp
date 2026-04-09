import Foundation
import SwiftUI

extension BillViewModel {
    func loadCreateContext(eventId: UUID?, scannedItems: [BillItem]) async {
        if items.isEmpty {
            items = scannedItems
        }

        guard let eventId else {
            // Загружаем локальных друзей как участников
            if let friendsRepository {
                do {
                    let localFriends = try await friendsRepository.listLocalFriends()
                    print("🔍 BillViewModel загрузил \(localFriends.count) локальных друзей")
                    for friend in localFriends {
                        print("  - \(friend.name) (id: \(friend.id))")
                    }
                    participants = localFriends.map { friend in
                        let initials = friend.name.split(separator: " ")
                            .prefix(2)
                            .compactMap { $0.first }
                            .map { String($0).uppercased() }
                            .joined()

                        return Participant(
                            id: friend.id,
                            name: friend.name,
                            initials: initials.isEmpty ? "?" : initials,
                            color: .accentColor
                        )
                    }
                    print("✅ BillViewModel создал \(participants.count) участников")
                } catch {
                    print("❌ Ошибка загрузки локальных друзей в BillViewModel: \(error)")
                    participants = []
                }
            } else {
                print("⚠️ BillViewModel: friendsRepository отсутствует")
                participants = []
            }
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
        CreateReceiptCommand(
            payerId: payerId,
            title: nil,
            totalAmount: NSDecimalNumber(decimal: total).doubleValue,
            items: items.compactMap { item in
                guard !item.assignedTo.isEmpty else { return nil }

                return CreateReceiptItemCommand(
                    name: item.name.isEmpty ? nil : item.name,
                    cost: NSDecimalNumber(decimal: item.amount).doubleValue,
                    shareItems: item.assignedTo.map { assignedTo in
                        CreateShareItemCommand(
                            userId: assignedTo.id,
                            shareValue: 1
                        )
                    }
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
