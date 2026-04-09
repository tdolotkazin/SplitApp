import Foundation
import SwiftUI
import Combine

@MainActor
class FriendsViewModel: ObservableObject {
    @Published var friends: [Friend] = []
    @Published var debts: [FriendDebt] = []
    @Published var searchText: String = ""
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let friendsRepository: any FriendsRepository
    private let eventsRepository: any EventsRepository
    private let balancesRepository: any BalancesRepository
    private let currentUserId: UUID

    var activeDebts: [FriendDebt] {
        debts.filter { $0.amount > 0 }
    }

    var filteredFriends: [Friend] {
        if searchText.isEmpty {
            return friends
        }
        return friends.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    init(
        friendsRepository: any FriendsRepository,
        eventsRepository: any EventsRepository,
        balancesRepository: any BalancesRepository,
        currentUserId: UUID = UUID()
    ) {
        self.friendsRepository = friendsRepository
        self.eventsRepository = eventsRepository
        self.balancesRepository = balancesRepository
        self.currentUserId = currentUserId
    }

    func loadFriends() async {
        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil

        do {
            async let remoteFriends = try friendsRepository.listRemoteFriends()
            async let localFriends = try friendsRepository.listLocalFriends()

            let (remoteUsers, locals) = try await (remoteFriends, localFriends)

            let remoteFriendsList = remoteUsers.map { Friend.from(user: $0) }
            let localFriendsList = locals.map { Friend.from(localFriend: $0) }

            var allFriends = remoteFriendsList + localFriendsList

            // Fallback: если нет друзей, показываем моковые данные для демонстрации
            if allFriends.isEmpty {
                print("⚠️ Нет друзей с сервера, показываю моковые данные")
                allFriends = loadMockFriends()
            }

            let calculatedDebts = try await calculateDebts(friends: allFriends)

            self.friends = allFriends
            self.debts = calculatedDebts

        } catch {
            errorMessage = error.localizedDescription
            print("❌ Ошибка загрузки друзей: \(error)")
            // При ошибке тоже показываем моковые данные
            self.friends = loadMockFriends()
            self.debts = loadMockDebts()
        }

        isLoading = false
    }

    func settleDebt(_ debt: FriendDebt) {
        debts.removeAll { $0.id == debt.id }
    }

    private func calculateDebts(friends: [Friend]) async throws -> [FriendDebt] {
        let events = try await eventsRepository.listEvents(userId: currentUserId)

        var netBalances: [UUID: Double] = [:]

        for event in events {
            do {
                let balances = try await balancesRepository.getEventBalances(eventId: event.id)

                for balance in balances {
                    if balance.debitorId == currentUserId {
                        let current = netBalances[balance.creditorId] ?? 0
                        netBalances[balance.creditorId] = current - balance.amount
                    } else if balance.creditorId == currentUserId {
                        let current = netBalances[balance.debitorId] ?? 0
                        netBalances[balance.debitorId] = current + balance.amount
                    }
                }
            } catch {
                print("⚠️ Не удалось загрузить балансы для события \(event.id): \(error)")
            }
        }

        var friendDebts: [FriendDebt] = []

        for (userId, netAmount) in netBalances {
            guard abs(netAmount) > 0.01 else { continue }

            if let friend = friends.first(where: { $0.userId == userId }) {
                let type: DebtType = netAmount > 0 ? .owedBy : .owes
                let absAmount = abs(netAmount)

                friendDebts.append(
                    FriendDebt(
                        friend: friend,
                        amount: Decimal(absAmount),
                        type: type
                    )
                )
            }
        }

        return friendDebts
    }

    private func loadMockFriends() -> [Friend] {
        return [
            Friend(name: "Артём Романов", initials: "АР", color: Color(hex: "#FFB5A7")),
            Friend(name: "Маша Соколова", initials: "МС", color: Color(hex: "#A7D8FF")),
            Friend(name: "Серёжа Козлов", initials: "СК", color: Color(hex: "#D4C5F9")),
            Friend(name: "Юля Петрова", initials: "ЮП", color: Color(hex: "#C9F7F5"))
        ]
    }

    private func loadMockDebts() -> [FriendDebt] {
        let mockFriends = loadMockFriends()
        return [
            FriendDebt(friend: mockFriends[0], amount: 12.00, type: .owedBy),
            FriendDebt(friend: mockFriends[1], amount: 18.50, type: .owes)
        ]
    }
}
