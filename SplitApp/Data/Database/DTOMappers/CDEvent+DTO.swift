import CoreData

extension CDEvent {
    /// Convert CoreData entity to DTO.
    func toDTO() -> EventDTO {
        let participantSet = (participants as? Set<CDUser>) ?? []
        let participantIds: [UUID] = participantSet.compactMap(\.id)
        let participantDTOs = participantSet.map { $0.toDTO() }

        return EventDTO(
            id: id!,
            creatorId: creatorId!,
            name: name!,
            isClosed: isClosed,
            users: participantIds,
            participants: participantDTOs,
            createdAt: createdAt!,
            updatedAt: updatedAt!
        )
    }

    /// Update CoreData entity from DTO (does not update relationships).
    func update(from dto: EventDTO) {
        id = dto.id
        creatorId = dto.creatorId
        name = dto.name
        isClosed = dto.isClosed
        createdAt = dto.createdAt
        updatedAt = dto.updatedAt
    }
}
