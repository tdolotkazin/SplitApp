import Foundation

final class AppDependencies {
    let apiClient: APIClient
    let coreDataStore: CoreDataStore
    let networkMonitor: NetworkMonitor

    let eventsRepository: any EventsRepository
    let receiptsRepository: any ReceiptsRepository
    let usersRepository: any UsersRepository
    let balancesRepository: any BalancesRepository
    let paymentsRepository: any PaymentsRepository
    let activeEventRepository: any ActiveEventRepository
    let friendsRepository: any FriendsRepository

    let eventManagementService: EventManagementServiceProtocol

    init(
        apiClient: APIClient = .shared,
        coreDataStore: CoreDataStore = .shared,
        networkMonitor: NetworkMonitor = .shared,
        eventsRepository: (any EventsRepository)? = nil,
        receiptsRepository: (any ReceiptsRepository)? = nil,
        usersRepository: (any UsersRepository)? = nil,
        balancesRepository: (any BalancesRepository)? = nil,
        paymentsRepository: (any PaymentsRepository)? = nil
    ) {
        self.apiClient = apiClient
        self.coreDataStore = coreDataStore
        self.networkMonitor = networkMonitor

        self.eventsRepository =
            eventsRepository
            ?? EventsDataRepository(
                apiClient: apiClient,
                coreDataStore: coreDataStore
            )

        self.receiptsRepository =
            receiptsRepository
            ?? ReceiptsDataRepository(
                apiClient: apiClient,
                coreDataStore: coreDataStore
            )

        self.usersRepository =
            usersRepository
            ?? UsersDataRepository(
                apiClient: apiClient,
                coreDataStore: coreDataStore
            )
        self.balancesRepository =
            balancesRepository ?? BalancesDataRepository(apiClient: apiClient)
        self.paymentsRepository =
            paymentsRepository
            ?? PaymentsDataRepository(
                apiClient: apiClient,
                coreDataStore: coreDataStore
            )
        self.activeEventRepository = ActiveEventSelectionDataRepository()
        self.friendsRepository = FriendsDataRepository(
            usersRepository: self.usersRepository
        )

        self.eventManagementService = EventManagementService(
            eventsRepository: self.eventsRepository
        )
    }

    static let live = AppDependencies()

    static let preview = AppDependencies(
        apiClient: .shared,
        coreDataStore: .shared,
        networkMonitor: .shared,
        eventsRepository: EventsDataRepository(),
        receiptsRepository: ReceiptsDataRepository(),
        usersRepository: UsersDataRepository(),
        balancesRepository: BalancesDataRepository(),
        paymentsRepository: PaymentsDataRepository()
    )
}
