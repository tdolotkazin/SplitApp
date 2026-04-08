import Foundation

struct User: Codable, Hashable {
    let id: UUID
    let name: String
    let phoneNumber: String
    let email: String

    enum CodingKeys: String, CodingKey {
        case id = "id"
        case name = "name"
        case phoneNumber = "phone_number"
        case email = "email"
    }

}
