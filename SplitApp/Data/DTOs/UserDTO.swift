import Foundation

struct UserDTO: Codable, Identifiable {
    let id: UUID
    let name: String
    let phoneNumber: String

    enum CodingKeys: String, CodingKey {
        case id, name
        case phoneNumber = "phone_number"
    }
}

struct CreateUserRequest: Codable {
    let name: String
    let phoneNumber: String

    enum CodingKeys: String, CodingKey {
        case name
        case phoneNumber = "phone_number"
    }
}
