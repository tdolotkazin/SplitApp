import Foundation

protocol FriendsRepository {
    /// Online-first: remote users first, local cache fallback.
    func listRemoteFriends() async throws -> [User]

    /// Temporary local friend operations until dedicated backend endpoints are available.
    func listLocalFriends() async throws -> [LocalFriend]
    func addLocalFriend(name: String) async throws -> LocalFriend
    func deleteLocalFriend(id: UUID) async throws

    /// Temporary local debts used by Friends screen.
    func listLocalDebts() async throws -> [LocalFriendDebt]
    func settleLocalDebt(id: UUID) async throws
}
