import Foundation

enum UserMapper {
    static func mapToDomain(dto: UserDTO) -> User {
        User(id: dto.id, name: dto.name, phoneNumber: dto.phoneNumber, email: dto.email)
    }
}
