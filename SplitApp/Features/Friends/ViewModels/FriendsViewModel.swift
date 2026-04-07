import Foundation
import SwiftUI
import Combine

@MainActor
class FriendsViewModel: ObservableObject {
    @Published var friends: [Friend] = []
    @Published var debts: [FriendDebt] = []
    @Published var searchText: String = ""

    var activeDebts: [FriendDebt] {
        debts.filter { $0.amount > 0 }
    }

    var filteredFriends: [Friend] {
        if searchText.isEmpty {
            return friends
        }
        return friends.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    init() {
        loadMockData()
    }

    func settleDebt(_ debt: FriendDebt) {
        debts.removeAll { $0.id == debt.id }
    }
}

private extension FriendsViewModel {
    func loadMockData() {
        friends = [
            Friend(name: "Артём Романов", initials: "АР", color: Color(hex: "#FFB5A7")),
            Friend(name: "Маша Соколова", initials: "МС", color: Color(hex: "#A7D8FF")),
            Friend(name: "Серёжа Козлов", initials: "СК", color: Color(hex: "#D4C5F9")),
            Friend(name: "Юля Петрова", initials: "ЮП", color: Color(hex: "#C9F7F5"))
        ]

        debts = [
            FriendDebt(friend: friends[0], amount: 12.00, type: .owedBy),
            FriendDebt(friend: friends[1], amount: 18.50, type: .owes)
        ]
    }
}
