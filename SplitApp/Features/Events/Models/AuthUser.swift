import Foundation

struct AuthUser {
    let id: UUID
    let name: String

    init(name: String) {
        self.id = UUID()
        self.name = name
    }
}
