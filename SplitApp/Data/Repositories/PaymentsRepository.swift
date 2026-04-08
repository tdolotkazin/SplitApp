import Foundation
import CoreData

final class PaymentsDataRepository: PaymentsRepository {
    private let apiClient: APIClient
    private let coreDataStore: CoreDataStore

    init(apiClient: APIClient = .shared, coreDataStore: CoreDataStore = .shared) {
        self.apiClient = apiClient
        self.coreDataStore = coreDataStore
    }

    func createPayment(eventId: UUID, _ command: CreatePaymentCommand) async throws -> Payment {
        let request = CreatePaymentRequest(
            senderId: command.senderId,
            receiverId: command.receiverId,
            amount: command.amount
        )
        let dto: PaymentDTO = try await apiClient.request(
            endpoint: CreatePaymentEndpoint(eventId: eventId),
            body: request
        )
        try await coreDataStore.performBackground { [weak self] context in
            try self?.upsertPayment(dto, in: context)
        }
        return PaymentMapper.mapToDomain(dto: dto)
    }

    func listPayments(eventId: UUID) async throws -> [Payment] {
        do {
            let dtos: [PaymentDTO] = try await apiClient.request(endpoint: ListPaymentsEndpoint(eventId: eventId))
            try await coreDataStore.performBackground { [weak self] context in
                try self?.upsertPayments(dtos, in: context)
            }
            return try await getCachedPayments(eventId: eventId)
        } catch {
            let cached = try await getCachedPayments(eventId: eventId)
            if cached.isEmpty {
                throw RepositoryError.offlineNoCache
            }
            return cached
        }
    }

    func updatePayment(id: UUID, _ command: UpdatePaymentCommand) async throws -> Payment {
        let request = UpdatePaymentRequest(confirmed: command.confirmed)
        let dto: PaymentDTO = try await apiClient.request(
            endpoint: UpdatePaymentEndpoint(id: id),
            body: request
        )
        try await coreDataStore.performBackground { [weak self] context in
            try self?.upsertPayment(dto, in: context)
        }
        return PaymentMapper.mapToDomain(dto: dto)
    }

    private func getCachedPayments(eventId: UUID) async throws -> [Payment] {
        try await coreDataStore.performBackground { context in
            let fetchRequest: NSFetchRequest<CDPayment> = CDPayment.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "eventId == %@", eventId as CVarArg)
            fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \CDPayment.createdAt, ascending: false)]
            let payments = try context.fetch(fetchRequest)
            return payments.map { PaymentMapper.mapToDomain(dto: $0.toDTO()) }
        }
    }

    private func upsertPayment(_ dto: PaymentDTO, in context: NSManagedObjectContext) throws {
        let fetchRequest: NSFetchRequest<CDPayment> = CDPayment.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", dto.id as CVarArg)
        fetchRequest.fetchLimit = 1

        let existing = try context.fetch(fetchRequest).first
        let payment = existing ?? CDPayment(context: context)
        payment.update(from: dto)
    }

    private func upsertPayments(_ dtos: [PaymentDTO], in context: NSManagedObjectContext) throws {
        for dto in dtos {
            try upsertPayment(dto, in: context)
        }
    }
}
