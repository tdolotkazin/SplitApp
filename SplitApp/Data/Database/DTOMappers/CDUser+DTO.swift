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
        self.id = dto.id
        self.name = dto.name
        self.phoneNumber = dto.phoneNumber
        self.email = dto.email
        self.avatarUrl = dto.avatarUrl
    }
}
