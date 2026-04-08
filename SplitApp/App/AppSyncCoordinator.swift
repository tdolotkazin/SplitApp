import Foundation

actor AppSyncCoordinator {
    private let eventsRepository: any EventsRepository
    private var hasCompletedInitialSync = false
    private var isSyncInProgress = false

    init(eventsRepository: any EventsRepository) {
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
