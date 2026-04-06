import Foundation

// TODO: If you want to decouple DTOs and CoreData from the Features completely, 
// Domain mappers convert lower-level representations into Domain models used by UI/Services.
enum EventMapper {
    static func mapToDomain(dto: EventDTO) -> Event {
        Event(
            id: dto.id,
            name: dto.name,
            positions: [], // Aggregate from other sources or leave empty if not fetched
            date: dto.createdAt,
            icon: "📌", // Add icon logic if present in backend later
            participantsCount: dto.users.count,
            balanceDelta: 0 // Fetch from EventBalanceDTO later
        )
    }

    // Example map from CDEvent (Assuming CDEvent properties exist)
    // static func mapToDomain(cdEvent: CDEvent) -> Event { ... }
}
