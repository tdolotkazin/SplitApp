import Foundation

protocol EventManagementServiceProtocol {
    func fetchHomeData() -> EventsHomeData
    func fetchReceiptDraft() -> ReceiptDraft
}

struct MockEventManagementService: EventManagementServiceProtocol {
    func fetchHomeData() -> EventsHomeData {
        let users = makeMockUsers()
        let events = makeMockEvents(users: users)

        return EventsHomeData(
            balanceSummary: EventBalanceSummary(
                totalBalance: 34.50,
                owedToYou: 89.00,
                youOwe: 54.50
            ),
            events: events
        )
    }

    func fetchReceiptDraft() -> ReceiptDraft {
        let participants = [
            ReceiptParticipant(initials: "АР", name: "Артём", tone: .orange),
            ReceiptParticipant(initials: "МС", name: "Маша", tone: .mint),
            ReceiptParticipant(initials: "ИВ", name: "Иван", tone: .indigo)
        ]

        let draft = [
            ReceiptLineItem(
                title: "Пицца\nМаргарита",
                amount: 12,
                participant: participants[safe: 0],
                isPlaceholder: false
            ),
            ReceiptLineItem(
                title: "Пицца\nПепперони",
                amount: 13,
                participant: participants[safe: 1],
                isPlaceholder: false
            ),
            ReceiptLineItem(
                title: "Газировка",
                amount: 8,
                participant: participants[safe: 2],
                isPlaceholder: false
            ),
            ReceiptLineItem(
                title: "Десерт",
                amount: 0,
                participant: nil,
                isPlaceholder: true
            )
        ]

        return ReceiptDraft(lineItems: draft, participants: participants)
    }

    private func makeMockUsers() -> [User] {
        [
            User(from: AuthUser(name: "Артём")),
            User(from: AuthUser(name: "Маша")),
            User(from: AuthUser(name: "Иван"))
        ]
    }

    private func makeMockEvents(users: [User]) -> [Event] {
        guard
            let artem = users[safe: 0],
            let masha = users[safe: 1],
            let ivan = users[safe: 2]
        else {
            return []
        }

        return [
            Event(
                name: "Пицца-пятница",
                positions: makePizzaPositions(artem: artem, masha: masha, ivan: ivan),
                icon: "🍕",
                participantsCount: 4,
                relativeDateText: "вчера",
                balanceDelta: 12
            ),
            Event(
                name: "Такси",
                positions: makeTaxiPositions(masha: masha, ivan: ivan),
                icon: "🚕",
                participantsCount: 2,
                relativeDateText: "3 дня",
                balanceDelta: -18
            ),
            Event(
                name: "Амстердам",
                positions: makeTripPositions(artem: artem, masha: masha, ivan: ivan),
                icon: "🏖️",
                participantsCount: 6,
                relativeDateText: "2 нед.",
                balanceDelta: nil
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

private extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
