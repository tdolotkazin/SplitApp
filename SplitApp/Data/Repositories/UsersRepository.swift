import Foundation
import CoreData

final class UsersDataRepository: UsersRepository {
    private let apiClient: APIClient
    private let coreDataStore: CoreDataStore

    init(apiClient: APIClient = .shared, coreDataStore: CoreDataStore = .shared) {
        self.apiClient = apiClient
        self.coreDataStore = coreDataStore
    }

    func createUser(_ command: CreateUserCommand) async throws -> User {
        let request = CreateUserRequest(name: command.name, phoneNumber: command.phoneNumber)
        let dto: UserDTO = try await apiClient.request(endpoint: CreateUserEndpoint(), body: request)
        try await coreDataStore.performBackground { [weak self] context in
            try self?.upsertUser(dto, in: context)
        }
        return UserMapper.mapToDomain(dto: dto)
    }

    func getUsers(ids: [UUID]) async throws -> [User] {
        try await coreDataStore.performBackground { context in
            let fetchRequest: NSFetchRequest<CDUser> = CDUser.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id IN %@", ids as NSArray)
            let cdUsers = try context.fetch(fetchRequest)
            return cdUsers.compactMap { UserMapper.mapToDomain(cdUser: $0) }
        }
    }

    private func upsertUser(_ dto: UserDTO, in context: NSManagedObjectContext) throws {
        let fetchRequest: NSFetchRequest<CDUser> = CDUser.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", dto.id as CVarArg)
        fetchRequest.fetchLimit = 1

        let existing = try context.fetch(fetchRequest).first
        let user = existing ?? CDUser(context: context)
        user.update(from: dto)
    }
}
