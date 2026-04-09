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
        self.id = dto.id
        self.creatorId = dto.creatorId
        self.name = dto.name
        self.isClosed = dto.isClosed
        self.createdAt = dto.createdAt
        self.updatedAt = dto.updatedAt
    }
}
