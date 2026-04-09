import CoreData

extension CDUser {
    /// Convert CoreData entity to DTO.
    func toDTO() -> UserDTO {
        UserDTO(
            id: id!,
            name: name!,
            phoneNumber: phoneNumber!,
            email: email,
            avatarUrl: avatarUrl
        )
    }

    /// Update CoreData entity from DTO.
    func update(from dto: UserDTO) {
        id = dto.id
        name = dto.name
        phoneNumber = dto.phoneNumber
        email = dto.email
        avatarUrl = dto.avatarUrl
    }
}
