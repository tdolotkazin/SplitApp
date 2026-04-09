import Foundation

final class FriendsDataRepository: FriendsRepository {
    private let usersRepository: any UsersRepository
    private let localStore: LocalFriendsStore

    init(
        usersRepository: any UsersRepository,
        localStore: LocalFriendsStore = LocalFriendsStore()
    ) {
        self.usersRepository = usersRepository
        self.localStore = localStore
    }

    func listRemoteFriends() async throws -> [User] {
        try await usersRepository.listUsers()
    }

    func listLocalFriends() async throws -> [LocalFriend] {
        try localStore.listLocalFriends()
    }

    func addLocalFriend(name: String) async throws -> LocalFriend {
        try localStore.addLocalFriend(name: name)
    }

    func listLocalDebts() async throws -> [LocalFriendDebt] {
        try localStore.listLocalDebts()
    }

    func settleLocalDebt(id: UUID) async throws {
        try localStore.settleLocalDebt(id: id)
    }
}
