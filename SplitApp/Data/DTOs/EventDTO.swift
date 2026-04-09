import Foundation

struct EventDTO: Codable, Identifiable {
    let id: UUID
    let creatorId: UUID
    let name: String
    let isClosed: Bool
    let users: [UUID]
    let participants: [UserDTO]?
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, name, users, participants
        case creatorId = "creator_id"
        case isClosed = "is_closed"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct CreateEventRequest: Codable {
    let name: String
}

struct UpdateEventRequest: Codable {
    let isClosed: Bool?
    let name: String?

    enum CodingKeys: String, CodingKey {
        case name
        case isClosed = "is_closed"
    }
}

struct AddParticipantsRequest: Codable {
    let userIds: [UUID]

    enum CodingKeys: String, CodingKey {
        case userIds = "user_ids"
    }
}
