import Foundation

actor AppSyncCoordinator {
    static let shared = AppSyncCoordinator()

    private let eventsRepository: EventsRepositoryProtocol
    private var hasCompletedInitialSync = false
    private var isSyncInProgress = false

    init(eventsRepository: EventsRepositoryProtocol = EventsRepository()) {
        self.eventsRepository = eventsRepository
    }

    func syncOnLaunchIfNeeded() async {
        guard !hasCompletedInitialSync else { return }
        guard !isSyncInProgress else { return }
        isSyncInProgress = true
        defer { isSyncInProgress = false }

        do {
            _ = try await eventsRepository.refreshEvents(userId: nil)
            hasCompletedInitialSync = true
        } catch {
            // Event screens still do their own refresh; startup sync is best-effort.
        }
    }
}
