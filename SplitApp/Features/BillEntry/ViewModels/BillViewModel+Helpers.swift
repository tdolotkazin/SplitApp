import Foundation
import SwiftUI

// swiftlint:disable file_length
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
            await loadMissingParticipantsForLoadedReceipt()
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
            await loadMissingParticipantsForLoadedReceipt()
            isUsingCachedData = false
        } catch {
            if loadedReceipt == nil {
                loadErrorMessage = error.localizedDescription
            } else {
                isUsingCachedData = true
                await loadMissingParticipantsForLoadedReceipt()
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
        case let .edit(_, receiptId):
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
        let eventParticipants = (event.participants + event.users).map(Self.makeParticipant)
        participants = mergeParticipants(eventParticipants)

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
        let participantsById = Dictionary(uniqueKeysWithValues: participants.map { ($0.id, $0) })

        return receipt.items.map { item in
            let assignedParticipants = item.shares.map { share in
                participantsById[share.userId] ?? Self.makeFallbackParticipant(for: share.userId)
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
        let trimmedTitle = receiptTitle.trimmingCharacters(in: .whitespacesAndNewlines)
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

    static func makeParticipant(from user: User) -> Participant {
        Participant(
            id: user.id,
            name: user.name,
            initials: makeInitials(from: user.name),
            color: makeStableColor(for: user.id),
            avatarURL: makeAvatarURL(from: user.avatarUrl)
        )
    }

    static let avatarColors: [Color] = [
        Color(hex: "#FFB5A7"),
        Color(hex: "#A7D8FF"),
        Color(hex: "#D4C5F9"),
        Color(hex: "#C9F7F5"),
        Color(hex: "#FADCB6"),
        Color(hex: "#C8F4CC")
    ]

    static func makeInitials(from name: String) -> String {
        let parts = name
            .split(separator: " ")
            .filter { !$0.isEmpty }

        if parts.count >= 2 {
            let first = String(parts[0].prefix(1))
            let second = String(parts[1].prefix(1))
            return (first + second).uppercased()
        }

        return String(name.prefix(2)).uppercased()
    }

    static func makeStableColor(for id: UUID) -> Color {
        let normalized = id.uuidString.replacingOccurrences(of: "-", with: "")
        let checksum = normalized.unicodeScalars.reduce(0) { partialResult, scalar in
            partialResult + Int(scalar.value)
        }
        let index = checksum % avatarColors.count
        return avatarColors[index]
    }

    static func makeAvatarURL(from value: String?) -> URL? {
        guard let value, !value.isEmpty else {
            return nil
        }

        return URL(string: value)
    }

    static func makeFallbackParticipant(for userId: UUID) -> Participant {
        return Participant(
            id: userId,
            name: "Неизвестный участник",
            initials: "?",
            color: makeStableColor(for: userId),
            avatarURL: nil
        )
    }

    func loadParticipantsFromBackendIfNeeded(for event: Event) async {
        let eventParticipants = (event.participants + event.users).map(Self.makeParticipant)
        participants = mergeParticipants(eventParticipants)

        do {
            let users = try await usersRepository.listUsers()
            participants = mergeParticipants(users.map(Self.makeParticipant))
        } catch {
            if let cached = try? await usersRepository.getCachedUsers() {
                participants = mergeParticipants(cached.map(Self.makeParticipant))
            }
        }

        if let loadedReceipt {
            let unresolved = missingShareUserIds(in: loadedReceipt, knownParticipants: participants)
            if !unresolved.isEmpty {
                let resolvedById = await resolveParticipantsByIds(unresolved)
                participants = mergeParticipants(resolvedById)
                let stillUnresolved = missingShareUserIds(in: loadedReceipt, knownParticipants: participants)
                if !stillUnresolved.isEmpty {
                    print("[BillParticipants] unresolved_after_event_load ids=\(stillUnresolved)")
                }
            }
            items = mapReceiptToBillItems(loadedReceipt, participants: participants)
        }
    }

    func ensureParticipantsInEvent(eventId: UUID, items: [BillItem], payerId: UUID) async throws {
        let eventParticipantIds = Set(loadedEvent?.participantIds ?? [])

        var neededIds = Set(items.flatMap { $0.assignedTo.map(\.id) })
        neededIds.insert(payerId)

        let missingIds = Array(neededIds.subtracting(eventParticipantIds))
        guard !missingIds.isEmpty else { return }

        _ = try await eventsRepository.addParticipants(
            eventId: eventId,
            AddParticipantsCommand(userIds: missingIds)
        )
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

    func loadMissingParticipantsForLoadedReceipt() async {
        guard let loadedReceipt else { return }
        let missingBeforeLoad = missingShareUserIds(in: loadedReceipt, knownParticipants: participants)
        guard !missingBeforeLoad.isEmpty else { return }

        do {
            let users = try await usersRepository.listUsers()
            participants = mergeParticipants(users.map(Self.makeParticipant))
        } catch {
            if let cachedUsers = try? await usersRepository.getCachedUsers() {
                participants = mergeParticipants(cachedUsers.map(Self.makeParticipant))
            }
        }

        let unresolved = missingShareUserIds(in: loadedReceipt, knownParticipants: participants)
        if !unresolved.isEmpty {
            let resolvedById = await resolveParticipantsByIds(unresolved)
            participants = mergeParticipants(resolvedById)
            let stillUnresolved = missingShareUserIds(in: loadedReceipt, knownParticipants: participants)
            if !stillUnresolved.isEmpty {
                print("[BillParticipants] unresolved_after_receipt_load ids=\(stillUnresolved)")
            }
        }

        items = mapReceiptToBillItems(loadedReceipt, participants: participants)
    }

    func normalizedShareValues(for participantCount: Int) -> [Double] {
        guard participantCount > 0 else { return [] }
        guard participantCount > 1 else { return [1.0] }

        let scale = 1_000_000
        let baseScaled = scale / participantCount
        let lastScaled = scale - baseScaled * (participantCount - 1)

        var values = Array(repeating: Double(baseScaled) / Double(scale), count: participantCount)
        values[participantCount - 1] = Double(lastScaled) / Double(scale)
        return values
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

    func missingShareUserIds(in receipt: Receipt, knownParticipants: [Participant]) -> [UUID] {
        let knownIds = Set(knownParticipants.map(\.id))
        let missingIds = Set(receipt.items.flatMap { item in
            item.shares.map(\.userId)
        }).subtracting(knownIds)

        return Array(missingIds)
    }

    func resolveParticipantsByIds(_ ids: [UUID]) async -> [Participant] {
        let users: [User]
        do {
            users = try await usersRepository.listUsers()
        } catch {
            guard let cachedUsers = try? await usersRepository.getCachedUsers() else {
                return []
            }
            return cachedUsers
                .filter { ids.contains($0.id) }
                .map(Self.makeParticipant)
        }

        return users
            .filter { ids.contains($0.id) }
            .map(Self.makeParticipant)
    }
}
// swiftlint:enable file_length
