import Foundation

final class LocalFriendsStore {
    private enum Keys {
        static let localFriends = "splitapp.local_friends"
        static let localDebts = "splitapp.local_friend_debts"
    }

    private let userDefaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func listLocalFriends() throws -> [LocalFriend] {
        try decode([LocalFriend].self, forKey: Keys.localFriends) ?? []
    }

    func addLocalFriend(name: String) throws -> LocalFriend {
        var friends = try listLocalFriends()
        let friend = LocalFriend(name: name)
        friends.append(friend)
        try encode(friends, forKey: Keys.localFriends)
        return friend
    }

    func listLocalDebts() throws -> [LocalFriendDebt] {
        try decode([LocalFriendDebt].self, forKey: Keys.localDebts) ?? []
    }

    func settleLocalDebt(id: UUID) throws {
        var debts = try listLocalDebts()
        debts.removeAll { $0.id == id }
        try encode(debts, forKey: Keys.localDebts)
    }

    private func encode<T: Encodable>(_ value: T, forKey key: String) throws {
        let data = try encoder.encode(value)
        userDefaults.set(data, forKey: key)
    }

    private func decode<T: Decodable>(_ type: T.Type, forKey key: String) throws -> T? {
        guard let data = userDefaults.data(forKey: key) else { return nil }
        return try decoder.decode(type, from: data)
    }
}
