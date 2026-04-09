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
        logOperation(
            op: "create",
            mode: "start",
            context: "eventId=\(eventId)"
        )

        do {
            let dto: ReceiptDTO = try await apiClient.request(
                endpoint: CreateReceiptEndpoint(eventId: eventId),
                body: request
            )

            try await persistDTOToLocalStores(dto)

            logOperation(
                op: "create",
                mode: "network_success",
                context: "eventId=\(eventId) receiptId=\(dto.id)"
            )
            logOperation(
                op: "create",
                mode: "network_cache_upsert",
                context: "eventId=\(eventId) receiptId=\(dto.id)"
            )
            return dto
        } catch {
            let localDTO = makeLocalCreateReceiptDTO(
                eventId: eventId,
                request: request
            )

            do {
                try await persistDTOToLocalStores(localDTO)
                logOperation(
                    op: "create",
                    mode: "local_fallback_success",
                    context: "eventId=\(eventId) receiptId=\(localDTO.id) networkError=\(error.localizedDescription)"
                )
                logOperation(
                    op: "create",
                    mode: "local_only",
                    context: "eventId=\(eventId) receiptId=\(localDTO.id)"
                )
                return localDTO
            } catch {
                logOperation(
                    op: "create",
                    mode: "network_failed_local_failed",
                    context: "eventId=\(eventId) error=\(error.localizedDescription)"
                )
                throw error
            }
        }
    }

    func listReceipts(eventId: UUID) async throws -> [ReceiptDTO] {
        logOperation(
            op: "list",
            mode: "start",
            context: "eventId=\(eventId)"
        )

        do {
            let dtos: [ReceiptDTO] = try await apiClient.request(endpoint: ListReceiptsEndpoint(eventId: eventId))

            logOperation(
                op: "list",
                mode: "network_success",
                context: "eventId=\(eventId) count=\(dtos.count)"
            )

            if dtos.isEmpty {
                let localReceipts = LocalReceiptsStore.shared.getReceipts(for: eventId)
                if !localReceipts.isEmpty {
                    logOperation(
                        op: "list",
                        mode: "local_fallback_success",
                        context: "eventId=\(eventId) count=\(localReceipts.count)"
                    )
                    return localReceipts
                }
            }

            try await coreDataStore.performBackground { [weak self] context in
                try self?.syncReceipts(dtos, eventId: eventId, in: context)
            }
            logOperation(
                op: "list",
                mode: "network_cache_upsert",
                context: "eventId=\(eventId) count=\(dtos.count)"
            )
            return dtos
        } catch {
            let localReceipts = LocalReceiptsStore.shared.getReceipts(for: eventId)
            if !localReceipts.isEmpty {
                logOperation(
                    op: "list",
                    mode: "local_fallback_success",
                    context: "eventId=\(eventId) count=\(localReceipts.count) networkError=\(error.localizedDescription)"
                )
            } else {
                logOperation(
                    op: "list",
                    mode: "network_failed_local_failed",
                    context: "eventId=\(eventId) error=\(error.localizedDescription)"
                )
            }
            return localReceipts
        }
    }

    func updateReceipt(id: UUID, _ request: UpdateReceiptRequest) async throws -> ReceiptDTO {
        logOperation(
            op: "update",
            mode: "start",
            context: "receiptId=\(id)"
        )

        do {
            let dto: ReceiptDTO = try await apiClient.request(endpoint: UpdateReceiptEndpoint(id: id), body: request)

            try await persistDTOToLocalStores(dto)

            logOperation(
                op: "update",
                mode: "network_success",
                context: "receiptId=\(id)"
            )
            logOperation(
                op: "update",
                mode: "network_cache_upsert",
                context: "receiptId=\(id)"
            )
            return dto
        } catch {
            guard let existingReceipt = LocalReceiptsStore.shared.getReceipt(id: id) else {
                logOperation(
                    op: "update",
                    mode: "network_failed_local_failed",
                    context: "receiptId=\(id) error=\(error.localizedDescription)"
                )
                throw error
            }
            let updatedDto = makeUpdatedReceiptDTO(
                id: id,
                request: request,
                existingReceipt: existingReceipt
            )

            do {
                try await persistDTOToLocalStores(updatedDto)
                logOperation(
                    op: "update",
                    mode: "local_fallback_success",
                    context: "receiptId=\(id) networkError=\(error.localizedDescription)"
                )
                logOperation(
                    op: "update",
                    mode: "local_only",
                    context: "receiptId=\(id)"
                )
                return updatedDto
            } catch {
                logOperation(
                    op: "update",
                    mode: "network_failed_local_failed",
                    context: "receiptId=\(id) error=\(error.localizedDescription)"
                )
                throw error
            }
        }
    }

    func createReceipt(eventId: UUID, _ command: CreateReceiptCommand) async throws -> Receipt {
        let request = CreateReceiptRequest(
            payerId: command.payerId,
            title: command.title,
            totalAmount: command.totalAmount,
            items: command.items.map(mapCreateReceiptItemCommand)
        )
        var dto: ReceiptDTO = try await apiClient.request(
            endpoint: CreateReceiptEndpoint(eventId: eventId),
            body: request
        )

        if let receiptImageJPEGData = command.receiptImageJPEGData {
            do {
                let uploadResponse = try await uploadReceiptImage(
                    receiptId: dto.id,
                    imageJPEGData: receiptImageJPEGData
                )
                dto = updateImageUrl(in: dto, imageUrl: uploadResponse.imageUrl)
            } catch {
                print("Не удалось загрузить фото чека \(dto.id): \(error)")
            }
        }

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
        let dto = try await updateReceipt(id: id, request)
        return mapToDomain(dto)
    }

    func deleteReceipt(id: UUID) async throws {
        try await apiClient.requestVoid(endpoint: DeleteReceiptEndpoint(id: id))
        try await coreDataStore.performBackground { [weak self] context in
            try self?.deleteLocalReceipt(id: id, in: context)
        }
    }
}

private extension ReceiptsDataRepository {
    func logOperation(op: String, mode: String, context: String) {
        print("[ReceiptsRepo] op=\(op) mode=\(mode) \(context)")
    }

    func persistDTOToLocalStores(_ dto: ReceiptDTO) async throws {
        try await coreDataStore.performBackground { [weak self] context in
            try self?.upsertReceipt(dto, in: context)
        }
        LocalReceiptsStore.shared.saveReceipt(dto)
    }

    func makeLocalCreateReceiptDTO(
        eventId: UUID,
        request: CreateReceiptRequest
    ) -> ReceiptDTO {
        let receiptId = UUID()
        let receiptItems = request.items.map { item in
            let receiptItemId = UUID()
            return ReceiptItemDTO(
                id: receiptItemId,
                receiptId: receiptId,
                name: item.name,
                cost: item.cost,
                shareItems: item.shareItems.map { shareItem in
                    ShareItemDTO(
                        id: UUID(),
                        receiptItemId: receiptItemId,
                        userId: shareItem.userId,
                        shareValue: shareItem.shareValue
                    )
                }
            )
        }

        return ReceiptDTO(
            id: receiptId,
            eventId: eventId,
            payerId: request.payerId,
            title: request.title,
            totalAmount: request.totalAmount,
            createdAt: Date(),
            updatedAt: Date(),
            items: receiptItems,
            imageUrl: nil
        )
    }

    func mapToDomain(_ dto: ReceiptDTO) -> Receipt {
        let items = dto.items.map { item in
            EventReceiptItem(
                id: item.id,
                name: item.name ?? "",
                cost: item.cost,
                shares: item.shareItems.map {
                    Share(
                        id: $0.id,
                        userId: $0.userId,
                        shareValue: $0.shareValue
                    )
                }
            )
        }

        return Receipt(
            id: dto.id,
            eventId: dto.eventId,
            payerId: dto.payerId,
            title: dto.title,
            totalAmount: dto.totalAmount,
            createdAt: dto.createdAt,
            items: items
        )
    }

    func makeUpdatedReceiptDTO(
        id: UUID,
        request: UpdateReceiptRequest,
        existingReceipt: ReceiptDTO
    ) -> ReceiptDTO {
        let baseItems = request.items ?? existingReceipt.items.map { existingItem in
            CreateReceiptItemRequest(
                name: existingItem.name,
                cost: existingItem.cost,
                shareItems: existingItem.shareItems.map { shareItem in
                    CreateShareItemRequest(
                        userId: shareItem.userId,
                        shareValue: shareItem.shareValue
                    )
                }
            )
        }
        let receiptItems = mapCreateItemsToReceiptItems(baseItems, receiptId: id)

        return ReceiptDTO(
            id: id,
            eventId: existingReceipt.eventId,
            payerId: existingReceipt.payerId,
            title: request.title ?? existingReceipt.title,
            totalAmount: request.totalAmount ?? existingReceipt.totalAmount,
            createdAt: existingReceipt.createdAt,
            updatedAt: Date(),
            items: receiptItems,
            imageUrl: existingReceipt.imageUrl
        )
    }

    func mapCreateItemsToReceiptItems(
        _ items: [CreateReceiptItemRequest],
        receiptId: UUID
    ) -> [ReceiptItemDTO] {
        items.map { item in
            let receiptItemId = UUID()
            return ReceiptItemDTO(
                id: receiptItemId,
                receiptId: receiptId,
                name: item.name,
                cost: item.cost,
                shareItems: item.shareItems.map { shareItem in
                    ShareItemDTO(
                        id: UUID(),
                        receiptItemId: receiptItemId,
                        userId: shareItem.userId,
                        shareValue: shareItem.shareValue
                    )
                }
            )
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

    private func uploadReceiptImage(
        receiptId: UUID,
        imageJPEGData: Data
    ) async throws -> ReceiptImageUploadResponseDTO {
        try await apiClient.requestMultipart(
            endpoint: UploadReceiptImageEndpoint(id: receiptId),
            fileFieldName: "file",
            fileName: "receipt-\(receiptId.uuidString).jpg",
            mimeType: "image/jpeg",
            fileData: imageJPEGData
        )
    }

    private func updateImageUrl(in dto: ReceiptDTO, imageUrl: String) -> ReceiptDTO {
        ReceiptDTO(
            id: dto.id,
            eventId: dto.eventId,
            payerId: dto.payerId,
            title: dto.title,
            totalAmount: dto.totalAmount,
            createdAt: dto.createdAt,
            updatedAt: dto.updatedAt,
            items: dto.items,
            imageUrl: imageUrl
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
            items: items,
            imageURL: cdReceipt.imageUrl
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
