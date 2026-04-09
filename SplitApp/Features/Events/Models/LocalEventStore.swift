import Foundation

/// Локальное хранилище данных текущего события
final class LocalEventStore {
    static let shared = LocalEventStore()
    private init() {}

    // Данные текущего события
    private(set) var currentEventId: UUID?
    private(set) var currentEventParticipants: [User] = []

    /// Мок-участники по умолчанию
    private let defaultParticipants: [User] = [
        User(id: UUID(), name: "Артём", phoneNumber: ""),
        User(id: UUID(), name: "Маша", phoneNumber: ""),
        User(id: UUID(), name: "Иван", phoneNumber: "")
    ]

    /// Устанавливает текущее событие с участниками
    func setCurrentEvent(id: UUID, participants: [User]) {
        currentEventId = id
        currentEventParticipants = participants.isEmpty ? defaultParticipants : participants
    }

    /// Возвращает участников текущего события (или мок-данные если нет события)
    func getCurrentParticipants() -> [User] {
        currentEventParticipants.isEmpty ? defaultParticipants : currentEventParticipants
    }

    /// Возвращает ID первого участника (используется как payer по умолчанию)
    func getDefaultPayerId() -> UUID {
        getCurrentParticipants().first?.id ?? UUID()
    }
}
