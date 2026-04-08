import Foundation

actor AppSyncCoordinator {
    static let shared = AppSyncCoordinator()

    private let eventsRepository: EventsRepositoryProtocol
    private var hasStarted = false

    init(eventsRepository: EventsRepositoryProtocol = EventsRepository()) {
        self.eventsRepository = eventsRepository
    }

    func syncOnLaunchIfNeeded() async {
        guard !hasStarted else { return }
        hasStarted = true

        do {
            _ = try await eventsRepository.refreshEvents(userId: nil)
        } catch {
            // Event screens still do their own refresh; startup sync is best-effort.
        }
    }
}
