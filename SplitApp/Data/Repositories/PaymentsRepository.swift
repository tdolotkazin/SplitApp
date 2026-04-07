import Foundation
import CoreData

protocol PaymentsRepositoryProtocol {
    func listPayments(eventId: UUID) async throws -> [PaymentDTO]
    func createPayment(eventId: UUID, _ request: CreatePaymentRequest) async throws -> PaymentDTO
    func updatePayment(id: UUID, _ request: UpdatePaymentRequest) async throws -> PaymentDTO
}

final class PaymentsRepository: PaymentsRepositoryProtocol {
    private let apiClient: APIClient
    private let coreDataStore: CoreDataStore

    init(apiClient: APIClient = .shared, coreDataStore: CoreDataStore = .shared) {
        self.apiClient = apiClient
        self.coreDataStore = coreDataStore
    }

    func createPayment(eventId: UUID, _ request: CreatePaymentRequest) async throws -> PaymentDTO {
        let dto: PaymentDTO = try await apiClient.request(
            endpoint: CreatePaymentEndpoint(eventId: eventId),
            body: request
        )
        try await coreDataStore.performBackground { [weak self] context in
            try self?.upsertPayment(dto, in: context)
        }
        return dto
    }

    func listPayments(eventId: UUID) async throws -> [PaymentDTO] {
        let dtos: [PaymentDTO] = try await apiClient.request(endpoint: ListPaymentsEndpoint(eventId: eventId))
        try await coreDataStore.performBackground { [weak self] context in
            try self?.upsertPayments(dtos, in: context)
        }
        return dtos
    }

    func updatePayment(id: UUID, _ request: UpdatePaymentRequest) async throws -> PaymentDTO {
        let dto: PaymentDTO = try await apiClient.request(
            endpoint: UpdatePaymentEndpoint(id: id),
            body: request
        )
        try await coreDataStore.performBackground { [weak self] context in
            try self?.upsertPayment(dto, in: context)
        }
        return dto
    }

    // MARK: - Core Data Internal Methods

    private func upsertPayment(_ dto: PaymentDTO, in context: NSManagedObjectContext) throws {
        let fetchRequest: NSFetchRequest<CDPayment> = CDPayment.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", dto.id as CVarArg)
        fetchRequest.fetchLimit = 1

        let existing = try context.fetch(fetchRequest).first
        let payment = existing ?? CDPayment(context: context)
        // Ensure CDPayment+DTO exists in DTOMappers
        payment.update(from: dto)
    }

    private func upsertPayments(_ dtos: [PaymentDTO], in context: NSManagedObjectContext) throws {
        for dto in dtos {
            try upsertPayment(dto, in: context)
        }
    }
}
