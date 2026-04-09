import Foundation

protocol ActiveEventRepository {
    func getActiveEventId() async -> UUID?
    func setActiveEventId(_ eventId: UUID) async
    func clearActiveEventId() async
}
