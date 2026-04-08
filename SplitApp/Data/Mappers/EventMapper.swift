import Foundation

enum EventMapper {

    /// Maps network/cache DTO to the domain model used by Services and UI.
    nonisolated static func mapToDomain(dto: EventDTO) -> Event {
        let participants = dto.participants?.map(UserMapper.mapToDomain(dto:)) ?? []
        let participantIds = participants.isEmpty ? dto.users : participants.map(\.id)

        return Event(
            id: dto.id,
            creatorId: dto.creatorId,
            name: dto.name,
            items: [],
            receipts: [],
            participants: participants,
            participantIds: participantIds,
            date: dto.createdAt,
            icon: "📌",
            participantsCount: participantIds.count,
            balanceDelta: 0
        )
    }

    /// Maps CoreData entity directly to the domain model (avoids intermediate DTO).
    nonisolated static func mapToDomain(cdEvent: CDEvent) -> Event? {
        guard let id = cdEvent.id,
              let name = cdEvent.name,
              let createdAt = cdEvent.createdAt else {
            return nil
        }

        let participantIds = (cdEvent.participants as? Set<CDUser>)?
            .compactMap { $0.id } ?? []
        let participants = (cdEvent.participants as? Set<CDUser>)?
            .compactMap(UserMapper.mapToDomain(cdUser:))
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending } ?? []

        return Event(
            id: id,
            creatorId: cdEvent.creatorId ?? UUID(),
            name: name,
            items: [],
            receipts: [],
            participants: participants,
            participantIds: participantIds,
            date: createdAt,
            icon: "📌",
            participantsCount: participantIds.count,
            balanceDelta: 0
        )
    }
}
