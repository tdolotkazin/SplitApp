import Foundation

protocol UsersRepository {
    /// Online-first: network list first, fallback to cached users.
    func listUsers() async throws -> [User]
    /// Returns cached users only.
    func getCachedUsers() async throws -> [User]
}
