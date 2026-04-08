import Foundation

final class AppDependencies {
    let apiClient: APIClient
    let coreDataStore: CoreDataStore
    let networkMonitor: NetworkMonitor

    let eventsRepository: any EventsRepository
    let receiptsRepository: any ReceiptsRepository
    let usersRepository: any UsersRepository
    let paymentsRepository: any PaymentsRepository

    let eventManagementService: EventManagementServiceProtocol
    let appSyncCoordinator: AppSyncCoordinator

    init(
        apiClient: APIClient = .shared,
        coreDataStore: CoreDataStore = .shared,
        networkMonitor: NetworkMonitor = .shared,
        eventsRepository: (any EventsRepository)? = nil,
        receiptsRepository: (any ReceiptsRepository)? = nil,
        usersRepository: (any UsersRepository)? = nil,
        paymentsRepository: (any PaymentsRepository)? = nil
    ) {
        self.apiClient = apiClient
        self.coreDataStore = coreDataStore
        self.networkMonitor = networkMonitor

        self.eventsRepository = eventsRepository ?? EventsDataRepository(apiClient: apiClient, coreDataStore: coreDataStore)
        self.receiptsRepository = receiptsRepository ?? ReceiptsDataRepository(apiClient: apiClient, coreDataStore: coreDataStore)
        self.usersRepository = usersRepository ?? UsersDataRepository(apiClient: apiClient, coreDataStore: coreDataStore)
        self.paymentsRepository = paymentsRepository ?? PaymentsDataRepository(apiClient: apiClient, coreDataStore: coreDataStore)

        self.eventManagementService = EventManagementService(eventsRepository: self.eventsRepository)
        self.appSyncCoordinator = AppSyncCoordinator(eventsRepository: self.eventsRepository)
    }

    static let live = AppDependencies()

    static let preview = AppDependencies(
        apiClient: .shared,
        coreDataStore: .shared,
        networkMonitor: .shared,
        eventsRepository: EventsDataRepository(),
        receiptsRepository: ReceiptsDataRepository(),
        usersRepository: UsersDataRepository(),
        paymentsRepository: PaymentsDataRepository()
    )
}
