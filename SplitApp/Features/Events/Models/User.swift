import Foundation

struct User: Hashable {
    let id: UUID
    var name: String

    init(from authUser: AuthUser) {
        self.id = authUser.id
        self.name = authUser.name
    }
}
