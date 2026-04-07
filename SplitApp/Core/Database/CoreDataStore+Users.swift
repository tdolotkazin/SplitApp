import CoreData

extension CoreDataStore {

    /// Insert or update a single user from DTO.
    func upsertUser(_ dto: UserDTO, in context: NSManagedObjectContext) throws {
        let fetchRequest: NSFetchRequest<CDUser> = CDUser.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", dto.id as CVarArg)
        fetchRequest.fetchLimit = 1

        let existing = try context.fetch(fetchRequest).first
        let user = existing ?? CDUser(context: context)
        user.update(from: dto)
    }

    /// Insert or update multiple users from DTOs.
    func upsertUsers(_ dtos: [UserDTO], in context: NSManagedObjectContext) throws {
        for dto in dtos {
            try upsertUser(dto, in: context)
        }
    }

    /// Fetch a single user by ID.
    func fetchUser(id: UUID, in context: NSManagedObjectContext) throws -> CDUser? {
        let fetchRequest: NSFetchRequest<CDUser> = CDUser.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        fetchRequest.fetchLimit = 1
        return try context.fetch(fetchRequest).first
    }

    /// Fetch all users.
    func fetchAllUsers(in context: NSManagedObjectContext) throws -> [CDUser] {
        let fetchRequest: NSFetchRequest<CDUser> = CDUser.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \CDUser.name, ascending: true)]
        return try context.fetch(fetchRequest)
    }

    /// Delete a user by ID.
    func deleteUser(id: UUID, in context: NSManagedObjectContext) throws {
        guard let user = try fetchUser(id: id, in: context) else { return }
        context.delete(user)
    }
}
