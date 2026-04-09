import CoreData

extension CDUser {

    /// Convert CoreData entity to DTO.
    func toDTO() -> UserDTO {
        UserDTO(
            id: id!,
            name: name!,
            email: email!,
            phoneNumber: phoneNumber!

        )
    }

    /// Update CoreData entity from DTO.
    func update(from dto: UserDTO) {
        self.id = dto.id
        self.name = dto.name
        self.email = dto.email
        self.phoneNumber = dto.phoneNumber

    }
}
