import Foundation

protocol UsersRepository {
    func createUser(_ command: CreateUserCommand) async throws -> User
    func getUsers(ids: [UUID]) async throws -> [User]
}
