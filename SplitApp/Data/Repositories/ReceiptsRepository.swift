import Foundation
import CoreData

final class ReceiptsDataRepository: ReceiptsRepository {
    private let apiClient: APIClient
    private let coreDataStore: CoreDataStore

    init(apiClient: APIClient = .shared, coreDataStore: CoreDataStore = .shared) {
        self.apiClient = apiClient
        self.coreDataStore = coreDataStore
    }

    func createReceipt(eventId: UUID, _ request: CreateReceiptRequest) async throws -> ReceiptDTO {
        do {
            let dto: ReceiptDTO = try await apiClient.request(
                endpoint: CreateReceiptEndpoint(eventId: eventId),
                body: request
            )
            try await coreDataStore.performBackground { [weak self] context in
                try self?.upsertReceipt(dto, in: context)
            }
            return dto
        } catch {
            // Fallback: создаем чек локально если нет бэкенда
            let receiptItems = request.items.map { item in
                ReceiptItemDTO(
                    id: UUID(),
                    receiptId: UUID(), // Будет обновлено ниже
                    name: item.name,
                    cost: item.cost,
                    shareItems: item.shareItems.map { $0.userId }
                )
            }

            let dto = ReceiptDTO(
                id: UUID(),
                eventId: eventId,
                payerId: request.payerId,
                title: request.title,
                totalAmount: request.totalAmount,
                createdAt: Date(),
                updatedAt: Date(),
                items: receiptItems
            )

            LocalReceiptsStore.shared.saveReceipt(dto)
            return dto
        }
    }

    func listReceipts(eventId: UUID) async throws -> [ReceiptDTO] {
        do {
            print("🌐 ReceiptsRepository: Пытаемся загрузить чеки с API для события: \(eventId)")
            let dtos: [ReceiptDTO] = try await apiClient.request(endpoint: ListReceiptsEndpoint(eventId: eventId))
            print("🌐 ReceiptsRepository: Получено чеков с API: \(dtos.count)")

            // Если API вернул пустой список, проверяем локальное хранилище
            if dtos.isEmpty {
                let localReceipts = LocalReceiptsStore.shared.getReceipts(for: eventId)
                print("🌐 ReceiptsRepository: API вернул 0 чеков, проверяем локальное хранилище: \(localReceipts.count)")
                if !localReceipts.isEmpty {
                    return localReceipts
                }
            }

            try await coreDataStore.performBackground { [weak self] context in
                try self?.upsertReceipts(dtos, in: context)
            }
            return dtos
        } catch {
            print("🌐 ReceiptsRepository: Ошибка API: \(error), используем локальное хранилище")
            let localReceipts = LocalReceiptsStore.shared.getReceipts(for: eventId)
            print("🌐 ReceiptsRepository: Возвращаем локальные чеки: \(localReceipts.count)")
            return localReceipts
        }
    }

    func updateReceipt(id: UUID, _ request: UpdateReceiptRequest) async throws -> ReceiptDTO {
        do {
            let dto: ReceiptDTO = try await apiClient.request(endpoint: UpdateReceiptEndpoint(id: id), body: request)
            try await coreDataStore.performBackground { [weak self] context in
                try self?.upsertReceipt(dto, in: context)
            }
            return dto
        } catch {
            // Fallback: обновляем чек локально если нет бэкенда
            // Получаем существующий чек из локального хранилища
            guard let existingReceipt = LocalReceiptsStore.shared.getReceipt(id: id) else {
                throw error
            }

            // Преобразуем UpdateReceiptRequest обратно в ReceiptDTO
            let receiptItems = (request.items ?? existingReceipt.items.map { existingItem in
                CreateReceiptItemRequest(
                    name: existingItem.name,
                    cost: existingItem.cost,
                    shareItems: existingItem.shareItems.map { userId in
                        CreateShareItemRequest(userId: userId, shareValue: 0)
                    }
                )
            }).map { item in
                ReceiptItemDTO(
                    id: UUID(),
                    receiptId: id,
                    name: item.name,
                    cost: item.cost,
                    shareItems: item.shareItems.map { $0.userId }
                )
            }

            let updatedDto = ReceiptDTO(
                id: id,
                eventId: existingReceipt.eventId,
                payerId: existingReceipt.payerId,
                title: request.title ?? existingReceipt.title,
                totalAmount: request.totalAmount ?? existingReceipt.totalAmount,
                createdAt: existingReceipt.createdAt,
                updatedAt: Date(),
                items: receiptItems
            )

            LocalReceiptsStore.shared.updateReceipt(updatedDto)
            return updatedDto
        }
    }
    
    func createReceipt(eventId: UUID, _ command: CreateReceiptCommand) async throws -> Receipt {
        let request = CreateReceiptRequest(
            payerId: command.payerId,
            title: command.title,
            totalAmount: command.totalAmount,
            items: command.items.map(mapCreateReceiptItemCommand)
        )
        let dto: ReceiptDTO = try await apiClient.request(
            endpoint: CreateReceiptEndpoint(eventId: eventId),
            body: request
        )
        try await coreDataStore.performBackground { [weak self] context in
            try self?.upsertReceipt(dto, in: context)
        }
        return try await getCachedReceipt(id: dto.id)
    }

    func getCachedReceipts(eventId: UUID) async throws -> [Receipt] {
        try await coreDataStore.performBackground { context in
            let fetchRequest: NSFetchRequest<CDReceipt> = CDReceipt.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "eventId == %@", eventId as CVarArg)
            fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \CDReceipt.createdAt, ascending: false)]
            let cdReceipts = try context.fetch(fetchRequest)
            return cdReceipts.map { self.mapToDomain($0) }
        }
    }

    func refreshReceipts(eventId: UUID) async throws -> [Receipt] {
        let dtos: [ReceiptDTO] = try await apiClient.request(endpoint: ListReceiptsEndpoint(eventId: eventId))
        try await coreDataStore.performBackground { [weak self] context in
            try self?.syncReceipts(dtos, eventId: eventId, in: context)
        }
        return try await getCachedReceipts(eventId: eventId)
    }

    func getCachedReceipt(id: UUID) async throws -> Receipt {
        try await coreDataStore.performBackground { context in
            let fetchRequest: NSFetchRequest<CDReceipt> = CDReceipt.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            fetchRequest.fetchLimit = 1
            guard let cdReceipt = try context.fetch(fetchRequest).first else {
                throw RepositoryError.notFound
            }
            return self.mapToDomain(cdReceipt)
        }
    }

    func getReceipt(id: UUID, eventId: UUID, policy: ReceiptFetchPolicy) async throws -> Receipt {
        switch policy {
        case .localOnly:
            return try await getCachedReceipt(id: id)
        case .refreshIfPossible:
            do {
                let receipts = try await refreshReceipts(eventId: eventId)
                if let receipt = receipts.first(where: { $0.id == id }) {
                    return receipt
                }
                throw RepositoryError.notFound
            } catch {
                do {
                    return try await getCachedReceipt(id: id)
                } catch {
                    throw RepositoryError.offlineNoCache
                }
            }
        }
    }

    func updateReceipt(id: UUID, _ command: UpdateReceiptCommand) async throws -> Receipt {
        let request = UpdateReceiptRequest(
            title: command.title,
            totalAmount: command.totalAmount,
            items: command.items?.map(mapCreateReceiptItemCommand)
        )
        let dto: ReceiptDTO = try await apiClient.request(endpoint: UpdateReceiptEndpoint(id: id), body: request)
        try await coreDataStore.performBackground { [weak self] context in
            try self?.upsertReceipt(dto, in: context)
        }
        return try await getCachedReceipt(id: dto.id)
    }

    func deleteReceipt(id: UUID) async throws {
        try await apiClient.requestVoid(endpoint: DeleteReceiptEndpoint(id: id))
        try await coreDataStore.performBackground { [weak self] context in
            try self?.deleteLocalReceipt(id: id, in: context)
        }
    }

    private func mapCreateReceiptItemCommand(_ command: CreateReceiptItemCommand) -> CreateReceiptItemRequest {
        CreateReceiptItemRequest(
            name: command.name,
            cost: command.cost,
            shareItems: command.shareItems.map { share in
                CreateShareItemRequest(userId: share.userId, shareValue: share.shareValue)
            }
        )
    }

    private func mapToDomain(_ cdReceipt: CDReceipt) -> Receipt {
        let cdItems = ((cdReceipt.items as? Set<CDReceiptItem>) ?? [])
            .sorted { ($0.name ?? "") < ($1.name ?? "") }
        let items: [EventReceiptItem] = cdItems.compactMap { item in
            guard let itemId = item.id else { return nil }
            let cdShares = ((item.shareItems as? Set<CDShareItem>) ?? [])
                .sorted { $0.shareValue > $1.shareValue }
            let shares: [Share] = cdShares.compactMap { share in
                guard let shareId = share.id, let userId = share.userId else { return nil }
                return Share(id: shareId, userId: userId, shareValue: share.shareValue)
            }
            return EventReceiptItem(id: itemId, name: item.name ?? "", cost: item.cost, shares: shares)
        }

        return Receipt(
            id: cdReceipt.id ?? UUID(),
            eventId: cdReceipt.eventId ?? UUID(),
            payerId: cdReceipt.payerId ?? UUID(),
            title: cdReceipt.title,
            totalAmount: cdReceipt.totalAmount,
            createdAt: cdReceipt.createdAt ?? Date(),
            items: items
        )
    }

    private func upsertReceipt(_ dto: ReceiptDTO, in context: NSManagedObjectContext) throws {
        let fetchRequest: NSFetchRequest<CDReceipt> = CDReceipt.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", dto.id as CVarArg)
        fetchRequest.fetchLimit = 1

        let existing = try context.fetch(fetchRequest).first
        let receipt = existing ?? CDReceipt(context: context)
        receipt.update(from: dto)

        let eventFetch: NSFetchRequest<CDEvent> = CDEvent.fetchRequest()
        eventFetch.predicate = NSPredicate(format: "id == %@", dto.eventId as CVarArg)
        eventFetch.fetchLimit = 1
        receipt.event = try context.fetch(eventFetch).first

        let existingItems = receipt.items as? Set<CDReceiptItem> ?? []
        let dtoItemIds = Set(dto.items.map { $0.id })

        for item in existingItems where !dtoItemIds.contains(item.id ?? UUID()) {
            context.delete(item)
        }

        for itemDto in dto.items {
            let item = existingItems.first { $0.id == itemDto.id } ?? CDReceiptItem(context: context)
            item.update(from: itemDto)
            item.receipt = receipt
            try syncShareItems(itemDto.shareItems, for: item, in: context)
        }
    }

    private func syncReceipts(_ dtos: [ReceiptDTO], eventId: UUID, in context: NSManagedObjectContext) throws {
        let fetchRequest: NSFetchRequest<CDReceipt> = CDReceipt.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "eventId == %@", eventId as CVarArg)
        let existingReceipts = try context.fetch(fetchRequest)
        let dtoIds = Set(dtos.map(\.id))

        for receipt in existingReceipts where !dtoIds.contains(receipt.id ?? UUID()) {
            context.delete(receipt)
        }

        for dto in dtos {
            try upsertReceipt(dto, in: context)
        }
    }

    private func syncShareItems(
        _ dtos: [ShareItemDTO],
        for item: CDReceiptItem,
        in context: NSManagedObjectContext
    ) throws {
        let existingShares = item.shareItems as? Set<CDShareItem> ?? []
        let dtoIds = Set(dtos.map(\.id))

        for share in existingShares where !dtoIds.contains(share.id ?? UUID()) {
            context.delete(share)
        }

        for dto in dtos {
            let share = existingShares.first { $0.id == dto.id } ?? CDShareItem(context: context)
            share.update(from: dto)
            share.receiptItem = item
        }
    }

    private func deleteLocalReceipt(id: UUID, in context: NSManagedObjectContext) throws {
        let fetchRequest: NSFetchRequest<CDReceipt> = CDReceipt.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        fetchRequest.fetchLimit = 1
        if let receipt = try context.fetch(fetchRequest).first {
            context.delete(receipt)
        }
    }
}
