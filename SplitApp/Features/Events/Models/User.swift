import Foundation

struct User: Hashable {
    let id: UUID
    var name: String

    init(id: UUID, name: String) {
        self.id = id
        self.name = name
    }

    init(from authUser: AuthUser) {
        self.id = authUser.id
        self.name = authUser.name
    }
}
