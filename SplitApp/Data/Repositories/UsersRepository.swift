import CoreData
import Foundation

final class UsersDataRepository: UsersRepository {
    private let apiClient: APIClient
    private let coreDataStore: CoreDataStore

    init(apiClient: APIClient = .shared, coreDataStore: CoreDataStore = .shared) {
        self.apiClient = apiClient
        self.coreDataStore = coreDataStore
    }

    func listUsers() async throws -> [User] {
        do {
            let dtos: [UserDTO] = try await apiClient.request(endpoint: ListUsersEndpoint())
            try await coreDataStore.performBackground { [weak self] context in
                try self?.upsertUsers(dtos, in: context)
            }
            return try await getCachedUsers()
        } catch {
            let cached = try await getCachedUsers()
            if cached.isEmpty {
                throw RepositoryError.offlineNoCache
            }
            return cached
        }
    }

    func getCachedUsers() async throws -> [User] {
        try await coreDataStore.performBackground { context in
            let fetchRequest: NSFetchRequest<CDUser> = CDUser.fetchRequest()
            fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \CDUser.name, ascending: true)]
            let cdUsers = try context.fetch(fetchRequest)
            return cdUsers.compactMap { UserMapper.mapToDomain(cdUser: $0) }
        }
    }

    private func upsertUsers(
        _ dtos: [UserDTO],
        in context: NSManagedObjectContext
    ) throws {
        for dto in dtos {
            let fetchRequest: NSFetchRequest<CDUser> = CDUser.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", dto.id as CVarArg)
            fetchRequest.fetchLimit = 1

            let existing = try context.fetch(fetchRequest).first
            let user = existing ?? CDUser(context: context)
            user.update(from: dto)
        }
    }
}
