import Foundation
import CoreData

protocol UsersRepositoryProtocol {
    func createUser(_ request: CreateUserRequest) async throws -> User
}

final class UsersRepository: UsersRepositoryProtocol {
    private let apiClient: APIClient
    private let coreDataStore: CoreDataStore

    init(apiClient: APIClient = .shared, coreDataStore: CoreDataStore = .shared) {
        self.apiClient = apiClient
        self.coreDataStore = coreDataStore
    }

    func createUser(_ request: CreateUserRequest) async throws -> User {
        let dto: UserDTO = try await apiClient.request(endpoint: CreateUserEndpoint(), body: request)
        try await coreDataStore.performBackground { [weak self] context in
            try self?.upsertUser(dto, in: context)
        }
        return UserMapper.mapToDomain(dto: dto)
    }

    // MARK: - Core Data Internal Methods (Extracted from CoreDataStore+Users)

    private func upsertUser(_ dto: UserDTO, in context: NSManagedObjectContext) throws {
        let fetchRequest: NSFetchRequest<CDUser> = CDUser.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", dto.id as CVarArg)
        fetchRequest.fetchLimit = 1

        let existing = try context.fetch(fetchRequest).first
        let user = existing ?? CDUser(context: context)
        // Ensure CDUser+DTO exists in DTOMappers
        user.update(from: dto)
    }

    private func upsertUsers(_ dtos: [UserDTO], in context: NSManagedObjectContext) throws {
        for dto in dtos {
            try upsertUser(dto, in: context)
        }
    }
}
