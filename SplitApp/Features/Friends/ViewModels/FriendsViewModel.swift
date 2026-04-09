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
        guard !isLoading else {
            print("⚠️ Загрузка уже идёт, пропускаем")
            return
        }

        print("📱 Начинаем загрузку друзей...")
        isLoading = true
        errorMessage = nil

        // Загружаем удалённых и локальных друзей независимо
        var remoteUsers: [User] = []
        var locals: [LocalFriend] = []

        // Пытаемся загрузить с сервера (может упасть, но не критично)
        do {
            remoteUsers = try await friendsRepository.listRemoteFriends()
            print("🔍 Загружено с сервера: \(remoteUsers.count) друзей")
        } catch {
            print("⚠️ Не удалось загрузить с сервера: \(error)")
        }

        // Загружаем локальных друзей (должно всегда работать)
        do {
            locals = try await friendsRepository.listLocalFriends()
            print("🔍 Загружено локально: \(locals.count) друзей")
            for friend in locals {
                print("  - \(friend.name) (id: \(friend.id))")
            }
        } catch {
            print("❌ Ошибка загрузки локальных друзей: \(error)")
            errorMessage = error.localizedDescription
        }

        let remoteFriendsList = remoteUsers.map { Friend.from(user: $0) }
        let localFriendsList = locals.map { Friend.from(localFriend: $0) }

        let allFriends = remoteFriendsList + localFriendsList

        // Пытаемся посчитать долги (может упасть, но не критично)
        do {
            let calculatedDebts = try await calculateDebts(friends: allFriends)
            self.debts = calculatedDebts
        } catch {
            print("⚠️ Не удалось посчитать долги: \(error)")
            self.debts = []
        }

        self.friends = allFriends
        print("✅ Всего друзей после загрузки: \(self.friends.count)")

        isLoading = false
    }

    func addLocalFriend(name: String) async {
        do {
            let localFriend = try await friendsRepository.addLocalFriend(name: name)
            let friend = Friend.from(localFriend: localFriend)
            self.friends.append(friend)
            print("✅ Добавлен локальный друг: \(name) (id: \(localFriend.id))")
            print("✅ Текущее количество друзей: \(self.friends.count)")
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Ошибка добавления друга: \(error)")
        }
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
}
