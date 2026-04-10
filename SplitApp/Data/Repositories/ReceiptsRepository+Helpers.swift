import CoreData
import Foundation

extension ReceiptsDataRepository {
    func deleteReceipt(id: UUID) async throws {
        try await apiClient.requestVoid(endpoint: DeleteReceiptEndpoint(id: id))
        try await coreDataStore.performBackground { [weak self] context in
            try self?.deleteLocalReceipt(id: id, in: context)
        }
    }
}

extension ReceiptsDataRepository {
    func handleListReceiptsFallback(
        eventId: UUID,
        networkError: Error
    ) -> [ReceiptDTO] {
        let localReceipts = LocalReceiptsStore.shared.getReceipts(for: eventId)
        if !localReceipts.isEmpty {
            let context =
                "eventId=\(eventId) count=\(localReceipts.count) " +
                "networkError=\(networkError.localizedDescription)"
            logOperation(
                operation: "list",
                mode: "local_fallback_success",
                context: context
            )
        } else {
            logOperation(
                operation: "list",
                mode: "network_failed_local_failed",
                context: "eventId=\(eventId) error=\(networkError.localizedDescription)"
            )
        }

        return localReceipts
    }

    func handleUpdateReceiptFallback(
        id: UUID,
        request: UpdateReceiptRequest,
        networkError: Error
    ) async throws -> ReceiptDTO {
        guard let existingReceipt = LocalReceiptsStore.shared.getReceipt(id: id) else {
            logOperation(
                operation: "update",
                mode: "network_failed_local_failed",
                context: "receiptId=\(id) error=\(networkError.localizedDescription)"
            )
            throw networkError
        }

        let updatedDto = makeUpdatedReceiptDTO(
            id: id,
            request: request,
            existingReceipt: existingReceipt
        )

        do {
            try await persistDTOToLocalStores(updatedDto)
            logOperation(
                operation: "update",
                mode: "local_fallback_success",
                context: "receiptId=\(id) networkError=\(networkError.localizedDescription)"
            )
            logOperation(
                operation: "update",
                mode: "local_only",
                context: "receiptId=\(id)"
            )
            return updatedDto
        } catch {
            logOperation(
                operation: "update",
                mode: "network_failed_local_failed",
                context: "receiptId=\(id) error=\(error.localizedDescription)"
            )
            throw error
        }
    }

    func logOperation(operation: String, mode: String, context: String) {
        print("[ReceiptsRepo] op=\(operation) mode=\(mode) \(context)")
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
            items: items,
            imageURL: dto.imageUrl
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

    func mapCreateReceiptItemCommand(_ command: CreateReceiptItemCommand) -> CreateReceiptItemRequest {
        CreateReceiptItemRequest(
            name: command.name,
            cost: command.cost,
            shareItems: command.shareItems.map { share in
                CreateShareItemRequest(userId: share.userId, shareValue: share.shareValue)
            }
        )
    }

    func uploadReceiptImage(
        receiptId: UUID,
        imageJPEGData: Data
    ) async throws -> ReceiptImageUploadResponseDTO {
        do {
            return try await apiClient.requestMultipart(
                endpoint: UploadReceiptImageEndpoint(id: receiptId),
                fileFieldName: "file",
                fileName: "receipt-\(receiptId.uuidString).jpg",
                mimeType: "image/jpeg",
                fileData: imageJPEGData
            )
        } catch NetworkError.httpError(let statusCode, _)
            where statusCode == 400 || statusCode == 415 || statusCode == 422 {
            return try await apiClient.requestMultipart(
                endpoint: UploadReceiptImageEndpoint(id: receiptId),
                fileFieldName: "image",
                fileName: "receipt-\(receiptId.uuidString).jpg",
                mimeType: "image/jpeg",
                fileData: imageJPEGData
            )
        } catch {
            throw error
        }
    }

    func updateImageUrl(in dto: ReceiptDTO, imageUrl: String) -> ReceiptDTO {
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

    func mapToDomain(_ cdReceipt: CDReceipt) -> Receipt {
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

    func upsertReceipt(_ dto: ReceiptDTO, in context: NSManagedObjectContext) throws {
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
        let dtoItemIds = Set(dto.items.map(\.id))

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

    func syncReceipts(_ dtos: [ReceiptDTO], eventId: UUID, in context: NSManagedObjectContext) throws {
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

    func syncShareItems(
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

    func deleteLocalReceipt(id: UUID, in context: NSManagedObjectContext) throws {
        let fetchRequest: NSFetchRequest<CDReceipt> = CDReceipt.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        fetchRequest.fetchLimit = 1
        if let receipt = try context.fetch(fetchRequest).first {
            context.delete(receipt)
        }
    }
}
