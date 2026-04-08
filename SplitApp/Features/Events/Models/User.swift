import Foundation

extension User {
    init(from authUser: AuthUser) {
        self.init(
            id: UUID(uuidString: authUser.id) ?? UUID(),
            name: authUser.name,
            phoneNumber: ""
        )
    }
}
