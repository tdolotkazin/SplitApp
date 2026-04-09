import Combine
import Foundation
import SwiftUI

@MainActor
class FriendsViewModel: ObservableObject {
    @Published var friends: [Friend] = []
    @Published var debts: [FriendDebt] = []
    @Published var searchText: String = ""
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    private let friendsRepository: any FriendsRepository
    private var hasLoaded = false

    var activeDebts: [FriendDebt] {
        debts.filter { $0.amount > 0 }
    }

    var filteredFriends: [Friend] {
        if searchText.isEmpty {
            return friends
        }
        return friends.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    init(friendsRepository: any FriendsRepository) {
        self.friendsRepository = friendsRepository
        loadMockDebts()
    }

    func load() async {
        guard !hasLoaded else { return }
        hasLoaded = true
        await reload()
    }

    func reload() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let users = try await friendsRepository.listRemoteFriends()
            friends = users.map(Self.mapUserToFriend)
        } catch {
            errorMessage = "Не удалось загрузить друзей. Проверьте интернет и попробуйте снова."
            friends = []
        }
    }

    func settleDebt(_ debt: FriendDebt) {
        debts.removeAll { $0.id == debt.id }
    }
}

private extension FriendsViewModel {
    static let avatarColors: [Color] = [
        Color(hex: "#FFB5A7"),
        Color(hex: "#A7D8FF"),
        Color(hex: "#D4C5F9"),
        Color(hex: "#C9F7F5"),
        Color(hex: "#FADCB6"),
        Color(hex: "#C8F4CC"),
    ]

    func loadMockDebts() {
        let debtFriends = [
            Friend(name: "Артём Романов", initials: "АР", color: Color(hex: "#FFB5A7")),
            Friend(name: "Маша Соколова", initials: "МС", color: Color(hex: "#A7D8FF")),
        ]
        debts = [
            FriendDebt(friend: debtFriends[0], amount: 12.00, type: .owedBy),
            FriendDebt(friend: debtFriends[1], amount: 18.50, type: .owes),
        ]
    }

    static func mapUserToFriend(_ user: User) -> Friend {
        Friend(
            id: user.id,
            name: user.name,
            initials: makeInitials(from: user.name),
            color: makeStableColor(for: user.id),
            avatarURL: makeAvatarURL(from: user.avatarUrl)
        )
    }

    static func makeInitials(from name: String) -> String {
        let parts = name
            .split(separator: " ")
            .filter { !$0.isEmpty }

        if parts.count >= 2 {
            let first = String(parts[0].prefix(1))
            let second = String(parts[1].prefix(1))
            return (first + second).uppercased()
        }

        return String(name.prefix(2)).uppercased()
    }

    static func makeStableColor(for id: UUID) -> Color {
        let normalized = id.uuidString.replacingOccurrences(of: "-", with: "")
        let checksum = normalized.unicodeScalars.reduce(0) { partialResult, scalar in
            partialResult + Int(scalar.value)
        }
        let index = checksum % avatarColors.count
        return avatarColors[index]
    }

    static func makeAvatarURL(from value: String?) -> URL? {
        guard let value, !value.isEmpty else {
            return nil
        }
        return URL(string: value)
    }
}
