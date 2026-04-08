import Foundation

enum EventMapper {

    /// Maps network/cache DTO to the domain model used by Services and UI.
    static func mapToDomain(dto: EventDTO) -> Event {
        Event(
            id: dto.id,
            name: dto.name,
            positions: [],
            date: dto.createdAt,
            icon: "📌",
            participantsCount: dto.users.count,
            balanceDelta: 0
        )
    }

    /// Maps CoreData entity directly to the domain model (avoids intermediate DTO).
    static func mapToDomain(cdEvent: CDEvent) -> Event? {
        guard let id = cdEvent.id,
              let name = cdEvent.name,
              let createdAt = cdEvent.createdAt else {
            return nil
        }

        let participantCount = (cdEvent.participants as? Set<CDUser>)?.count ?? 0

        return Event(
            id: id,
            name: name,
            positions: [],
            date: createdAt,
            icon: "📌",
            participantsCount: participantCount,
            balanceDelta: 0
        )
    }
}
