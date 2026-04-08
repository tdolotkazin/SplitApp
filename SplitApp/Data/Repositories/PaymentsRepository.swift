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
        let dtos: [PaymentDTO] = try await apiClient.request(endpoint: ListPaymentsEndpoint(eventId: eventId))
        try await coreDataStore.performBackground { [weak self] context in
            try self?.upsertPayments(dtos, in: context)
        }
        return dtos.map(PaymentMapper.mapToDomain(dto:))
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
