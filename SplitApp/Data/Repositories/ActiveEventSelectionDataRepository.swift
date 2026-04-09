import Foundation

final class ActiveEventSelectionDataRepository: ActiveEventRepository {
    private let userDefaults: UserDefaults
    private let key = "splitapp.active_event_id"

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func getActiveEventId() async -> UUID? {
        guard let value = userDefaults.string(forKey: key) else { return nil }
        return UUID(uuidString: value)
    }

    func setActiveEventId(_ eventId: UUID) async {
        userDefaults.set(eventId.uuidString, forKey: key)
    }

    func clearActiveEventId() async {
        userDefaults.removeObject(forKey: key)
    }
}
