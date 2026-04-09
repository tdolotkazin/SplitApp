import SwiftUI

struct EventsNavigationView: View {
    @StateObject private var viewModel: EventsNavigationViewModel
    private let eventsRepository: any EventsRepository
    private let receiptsRepository: any ReceiptsRepository
    private let usersRepository: any UsersRepository
    private let networkMonitor: NetworkMonitor

    init(
        service: EventManagementServiceProtocol,
        eventsRepository: any EventsRepository,
        receiptsRepository: any ReceiptsRepository,
        usersRepository: any UsersRepository,
        networkMonitor: NetworkMonitor,
        rules: EventsNavigationRules = .init()
    ) {
        self.eventsRepository = eventsRepository
        self.receiptsRepository = receiptsRepository
        self.usersRepository = usersRepository
        self.networkMonitor = networkMonitor
        _viewModel = StateObject(
            wrappedValue: EventsNavigationViewModel(
                service: service,
                rules: rules
            )
        )
    }

    var body: some View {
        NavigationStack(path: $viewModel.path) {
            EventsHomeView(
                viewModel: viewModel.homeViewModel,
                onScanTap: { viewModel.handle(.scanButtonTapped) },
                onAddTap: { viewModel.handle(.addButtonTapped) },
                onBillTap: { billId in
                    guard let eventId = viewModel.homeViewModel.currentEvent?.id else {
                        return
                    }
                    viewModel.handle(.receiptTapped(eventId: eventId, receiptId: billId))
                },
                onEventTap: {
                    viewModel.handle(.currentEventTapped)
                }
            )
            .task {
                await viewModel.loadInitialDataIfNeeded()
            }
            .navigationDestination(for: EventsNavigationRoute.self) { route in
                switch route {
                case .scanner:
                    CameraView(
                        viewModel: viewModel.scannerViewModel,
                        onCapture: { viewModel.handle(.scannerCaptureCompleted) }
                    )
                    .navigationBarBackButtonHidden(true)

                case .eventPicker:
                    EventPickerView(viewModel: viewModel.homeViewModel)
                }
            }
        }
        .fullScreenCover(item: $viewModel.billEntryDestination) { destination in
            let billViewModel = BillViewModel(
                mode: destination.mode,
                eventsRepository: eventsRepository,
                receiptsRepository: receiptsRepository,
                usersRepository: usersRepository,
                networkMonitor: networkMonitor
            )

            BillEntryView(viewModel: billViewModel)
                .onDisappear {
                    Task { @MainActor in
                        if let eventId = LocalEventStore.shared.currentEventId {
                            await viewModel.homeViewModel.loadReceipts(for: eventId)
                        }
                        viewModel.didFinishBillEntry()
                    }
                }
        }
    }
}

#Preview {
    EventsNavigationView(
        service: EventManagementService(eventsRepository: EventsDataRepository()),
        eventsRepository: EventsDataRepository(),
        receiptsRepository: ReceiptsDataRepository(),
        usersRepository: UsersDataRepository(),
        networkMonitor: .shared
    )
}
