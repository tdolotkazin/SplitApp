import Foundation
import CoreData

protocol ReceiptsRepositoryProtocol {
    func listReceipts(eventId: UUID) async throws -> [ReceiptDTO]
    func createReceipt(eventId: UUID, _ request: CreateReceiptRequest) async throws -> ReceiptDTO
    func updateReceipt(id: UUID, _ request: UpdateReceiptRequest) async throws -> ReceiptDTO
    func deleteReceipt(id: UUID) async throws
}

final class ReceiptsRepository: ReceiptsRepositoryProtocol {
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
        let dto: ReceiptDTO = try await apiClient.request(endpoint: UpdateReceiptEndpoint(id: id), body: request)
        try await coreDataStore.performBackground { [weak self] context in
            try self?.upsertReceipt(dto, in: context)
        }
        return dto
    }

    func deleteReceipt(id: UUID) async throws {
        try await apiClient.requestVoid(endpoint: DeleteReceiptEndpoint(id: id))
        try await coreDataStore.performBackground { [weak self] context in
            try self?.deleteLocalReceipt(id: id, in: context)
        }
    }

    // MARK: - Core Data Internal Methods (Extracted from CoreDataStore+Receipts)

    private func upsertReceipt(_ dto: ReceiptDTO, in context: NSManagedObjectContext) throws {
        let fetchRequest: NSFetchRequest<CDReceipt> = CDReceipt.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", dto.id as CVarArg)
        fetchRequest.fetchLimit = 1

        let existing = try context.fetch(fetchRequest).first
        let receipt = existing ?? CDReceipt(context: context)
        // Ensure CDReceipt+DTO exists in DTOMappers
        receipt.update(from: dto)
    }

    private func upsertReceipts(_ dtos: [ReceiptDTO], in context: NSManagedObjectContext) throws {
        for dto in dtos {
            try upsertReceipt(dto, in: context)
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
