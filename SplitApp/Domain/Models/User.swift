import Foundation

struct User: Hashable, Decodable {
    let id: UUID
    var name: String
    let phoneNumber: String?
    let email: String?
    let avatarUrl: String?

    init(id: UUID, name: String, phoneNumber: String, email: String? = nil, avatarUrl: String? = nil) {
        self.id = id
        self.name = name
        self.phoneNumber = phoneNumber
        self.email = email
        self.avatarUrl = avatarUrl
    }
}
