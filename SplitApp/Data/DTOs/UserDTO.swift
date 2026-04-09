import Foundation

struct UserDTO: Codable, Identifiable {
    let id: UUID
    let name: String
    let phoneNumber: String
    let email: String?
    let avatarUrl: String?

    enum CodingKeys: String, CodingKey {
        case id, name, email
        case phoneNumber = "phone_number"
        case avatarUrl = "avatar_url"
    }
}
