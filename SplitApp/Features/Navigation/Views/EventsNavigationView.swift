import SwiftUI

struct EventsNavigationView: View {
    @StateObject private var viewModel: EventsNavigationViewModel
    private let eventsRepository: any EventsRepository
    private let receiptsRepository: any ReceiptsRepository
    private let networkMonitor: NetworkMonitor
    private let friendsRepository: any FriendsRepository

    init(
        service: EventManagementServiceProtocol,
        eventsRepository: any EventsRepository,
        receiptsRepository: any ReceiptsRepository,
        networkMonitor: NetworkMonitor,
        friendsRepository: any FriendsRepository,
        rules: EventsNavigationRules = .init()
    ) {
        self.eventsRepository = eventsRepository
        self.receiptsRepository = receiptsRepository
        self.networkMonitor = networkMonitor
        self.friendsRepository = friendsRepository
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
                    guard let eventId = LocalEventStore.shared.currentEventId else {
                        return
                    }
                    viewModel.handle(.receiptTapped(eventId: eventId, receiptId: billId))
                },
                onEventTap: { eventId in
                    viewModel.handle(.eventRowTapped(eventId))
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

                case .eventDetail(let eventId):
                    EventDetailView(
                        viewModel: EventDetailViewModel(
                            eventId: eventId,
                            service: viewModel.service,
                            receiptsRepository: receiptsRepository
                        ),
                        onAddReceipt: { viewModel.handle(.addReceiptTapped(eventId)) },
                        onReceiptTap: { receiptId in
                            viewModel.handle(
                                .receiptTapped(eventId: eventId, receiptId: receiptId)
                            )
                        }
                    )
                }
            }
        }
        .fullScreenCover(item: $viewModel.billEntryDestination) { destination in
            let billViewModel = BillViewModel(
                mode: destination.mode,
                eventsRepository: eventsRepository,
                receiptsRepository: receiptsRepository,
                networkMonitor: networkMonitor,
                friendsRepository: friendsRepository
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
    let deps = AppDependencies.preview
    return EventsNavigationView(
        service: deps.eventManagementService,
        eventsRepository: deps.eventsRepository,
        receiptsRepository: deps.receiptsRepository,
        networkMonitor: deps.networkMonitor,
        friendsRepository: deps.friendsRepository
    )
}
