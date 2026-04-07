import Foundation

protocol EventManagementServiceProtocol {
    func fetchHomeData() async -> EventsHomeData
}

struct EventManagementService: EventManagementServiceProtocol {
    func fetchHomeData() async -> EventsHomeData {
        let users = makeUsers()
        let events = makeEvents(users: users)

        return EventsHomeData(
            balanceSummary: EventBalanceSummary(
                totalBalance: 34.50,
                owedToYou: 89.00,
                youOwe: 54.50
            ),
            events: events
        )
    }

    private func makeUsers() -> [User] {
        [
            User(from: AuthUser(name: "Артём")),
            User(from: AuthUser(name: "Маша")),
            User(from: AuthUser(name: "Иван"))
        ]
    }

    private func makeEvents(users: [User]) -> [Event] {
        let artem = users[0]
        let masha = users[1]
        let ivan = users[2]

        let calendar = Calendar.current
        let now = Date()

        return [
            Event(
                name: "Пицца-пятница",
                positions: makePizzaPositions(artem: artem, masha: masha, ivan: ivan),
                date: calendar.date(byAdding: .day, value: -1, to: now) ?? now,
                icon: "🍕",
                participantsCount: 4,
                balanceDelta: 12
            ),
            Event(
                name: "Такси",
                positions: makeTaxiPositions(masha: masha, ivan: ivan),
                date: calendar.date(byAdding: .day, value: -3, to: now) ?? now,
                icon: "🚕",
                participantsCount: 2,
                balanceDelta: -18
            ),
            Event(
                name: "Амстердам",
                positions: makeTripPositions(artem: artem, masha: masha, ivan: ivan),
                date: calendar.date(byAdding: .day, value: -14, to: now) ?? now,
                icon: "🏖️",
                participantsCount: 6,
                balanceDelta: 0
            )
        ]
    }

    private func makePizzaPositions(artem: User, masha: User, ivan: User) -> [Position] {
        [
            Position(
                name: "Пицца Маргарита",
                amount: 12,
                participants: [PositionParticipant(userId: [artem, masha], shareAmount: 2)]
            ),
            Position(
                name: "Пицца Пепперони",
                amount: 13,
                participants: [PositionParticipant(userId: [artem, ivan], shareAmount: 2)]
            )
        ]
    }

    private func makeTaxiPositions(masha: User, ivan: User) -> [Position] {
        [
            Position(
                name: "Такси до дома",
                amount: 18,
                participants: [PositionParticipant(userId: [masha, ivan], shareAmount: 2)]
            )
        ]
    }

    private func makeTripPositions(artem: User, masha: User, ivan: User) -> [Position] {
        [
            Position(
                name: "Музей",
                amount: 0,
                participants: [PositionParticipant(userId: [artem, masha, ivan], shareAmount: 3)]
            )
        ]
    }
}
