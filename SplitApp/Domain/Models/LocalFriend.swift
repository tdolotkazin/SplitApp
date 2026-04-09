import Foundation

struct LocalFriend: Codable, Hashable, Identifiable {
    let id: UUID
    let name: String

    init(id: UUID = UUID(), name: String) {
        self.id = id
        self.name = name
    }
}
