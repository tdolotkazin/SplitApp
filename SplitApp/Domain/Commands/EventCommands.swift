import Foundation

struct CreateEventCommand {
    let creatorId: UUID
    let name: String
}

struct UpdateEventCommand {
    let isClosed: Bool?
    let name: String?
}

struct AddParticipantsCommand {
    let userIds: [UUID]
}
