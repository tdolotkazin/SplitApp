import Foundation

enum UserMapper {
    static func mapToDomain(dto: UserDTO) -> User {
        User(
            id: dto.id,
            name: dto.name,
            phoneNumber: dto.phoneNumber,
            email: dto.email,
            avatarUrl: dto.avatarUrl
        )
    }

    static func mapToDomain(cdUser: CDUser) -> User? {
        guard let id = cdUser.id, let name = cdUser.name, let phoneNumber = cdUser.phoneNumber else {
            return nil
        }
        return User(
            id: id,
            name: name,
            phoneNumber: phoneNumber,
            email: cdUser.email,
            avatarUrl: cdUser.avatarUrl
        )
    }
}
