import Foundation

struct UserDTO: Codable, Identifiable {
    let id: UUID
    let name: String
    let email: String
    let phoneNumber: String

    enum CodingKeys: String, CodingKey {
        case id, name, email
        case phoneNumber = "phone_number"
    }
}
