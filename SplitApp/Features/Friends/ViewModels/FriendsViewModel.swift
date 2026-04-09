import Foundation
import SwiftUI
import Combine

@MainActor
class FriendsViewModel: ObservableObject {
    @Published var friends: [Friend] = []
    @Published var debts: [FriendDebt] = []
    @Published var searchText: String = ""

    private let defaults: UserDefaults
    private let settledDebtIDsKey = "friends.settledDebtIDs.v1"

    var activeDebts: [FriendDebt] {
        debts.filter { $0.amount > 0 }
    }

    var filteredFriends: [Friend] {
        if searchText.isEmpty {
            return friends
        }
        return friends.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        loadMockData()
        applySettledDebts()
    }

    func settleDebt(_ debt: FriendDebt) {
        debts.removeAll { $0.id == debt.id }
        saveSettledDebtID(debt.id)
    }
}

private extension FriendsViewModel {
    func loadMockData() {
        let artem = Friend(
            id: uuid("E86411A9-EC8E-4F34-B8F4-B4721AA7B377"),
            name: "Артём Романов",
            initials: "АР",
            color: Color(hex: "#FFB5A7")
        )
        let masha = Friend(
            id: uuid("D09EA40E-FB99-4D20-A6D9-06EEDE97F730"),
            name: "Маша Соколова",
            initials: "МС",
            color: Color(hex: "#A7D8FF")
        )
        let sereza = Friend(
            id: uuid("929B53D5-AE35-41D5-AC4D-39C53C18C690"),
            name: "Серёжа Козлов",
            initials: "СК",
            color: Color(hex: "#D4C5F9")
        )
        let yulia = Friend(
            id: uuid("7F5007D9-F879-479A-BD62-052B188CFB8F"),
            name: "Юля Петрова",
            initials: "ЮП",
            color: Color(hex: "#C9F7F5")
        )

        friends = [artem, masha, sereza, yulia]

        debts = [
            FriendDebt(
                id: uuid("1B9082FE-7692-4DC7-9ED6-A8A252235C46"),
                friend: artem,
                amount: 12.00,
                type: .owedBy
            ),
            FriendDebt(
                id: uuid("7C8538A8-5B58-4EC8-B1D6-2B3B6236F1DA"),
                friend: masha,
                amount: 18.50,
                type: .owes
            )
        ]
    }

    func applySettledDebts() {
        let settledIDs = loadSettledDebtIDs()
        debts.removeAll { settledIDs.contains($0.id.uuidString) }
    }

    func saveSettledDebtID(_ id: UUID) {
        var settledIDs = loadSettledDebtIDs()
        settledIDs.insert(id.uuidString)
        defaults.set(Array(settledIDs), forKey: settledDebtIDsKey)
    }

    func loadSettledDebtIDs() -> Set<String> {
        Set(defaults.stringArray(forKey: settledDebtIDsKey) ?? [])
    }

    func uuid(_ value: String) -> UUID {
        guard let uuid = UUID(uuidString: value) else {
            preconditionFailure("Invalid static UUID: \(value)")
        }
        return uuid
    }
}
