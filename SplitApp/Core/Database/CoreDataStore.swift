import CoreData

final class CoreDataStore {

    static let shared = CoreDataStore()

    private let persistenceController: PersistenceController

    init(persistenceController: PersistenceController = .shared) {
        self.persistenceController = persistenceController
    }

    var viewContext: NSManagedObjectContext {
        persistenceController.viewContext
    }

    /// Perform a block on a background context and return the result.
    func performBackground<T: Sendable>(
        _ block: @escaping @Sendable (NSManagedObjectContext) throws -> T
    ) async throws -> T {
        let context = persistenceController.newBackgroundContext()
        return try await context.perform {
            let result = try block(context)
            if context.hasChanges {
                try context.save()
            }
            return result
        }
    }

    /// Perform a block on a background context (no return value).
    func performBackground(
        _ block: @escaping @Sendable (NSManagedObjectContext) throws -> Void
    ) async throws {
        let context = persistenceController.newBackgroundContext()
        try await context.perform {
            try block(context)
            if context.hasChanges {
                try context.save()
            }
        }
    }

    /// Save the given context if it has changes.
    func save(context: NSManagedObjectContext) throws {
        guard context.hasChanges else { return }
        try context.save()
    }
}
