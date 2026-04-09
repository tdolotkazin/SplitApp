import Foundation

struct CreateEventCommand {
    let name: String
}

struct UpdateEventCommand {
    let isClosed: Bool?
    let name: String?
}

struct AddParticipantsCommand {
    let userIds: [UUID]
}
