import SwiftUI

struct EventsNavigationView: View {
    @StateObject private var viewModel: EventsNavigationViewModel
    private let eventsRepository: any EventsRepository
    private let receiptsRepository: any ReceiptsRepository
    private let networkMonitor: NetworkMonitor

    init(
        service: EventManagementServiceProtocol,
        eventsRepository: any EventsRepository,
        receiptsRepository: any ReceiptsRepository,
        networkMonitor: NetworkMonitor,
        rules: EventsNavigationRules = .init()
    ) {
        self.eventsRepository = eventsRepository
        self.receiptsRepository = receiptsRepository
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
                    // Находим чек по ID в LocalReceiptsStore
                    if let eventId = LocalEventStore.shared.currentEventId {
                        let receipt = LocalReceiptsStore.shared.getReceipts(for: eventId)
                            .first(where: { $0.id == billId })
                        if let receipt = receipt {
                            viewModel.openReceiptForEdit(receipt)
                        }
                    }
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
                case .billEntry:
                    // BillEntry отображается через fullScreenCover ниже
                    EmptyView()
                }
            }
        }
        .fullScreenCover(isPresented: $viewModel.showBillEntry) {
            BillEntryView(
                eventId: LocalEventStore.shared.currentEventId,
                receipt: viewModel.editingReceipt,
                onReceiptCreated: {
                    Task { @MainActor in
                        // Сначала загружаем чеки
                        if let eventId = LocalEventStore.shared.currentEventId {
                            print("📱 Вызываем loadReceipts для события: \(eventId)")
                            await viewModel.homeViewModel.loadReceipts(for: eventId)
                            let billsCount = viewModel.homeViewModel
                                .currentEventBills.count
                            print("📱 currentEventBills.count после loadReceipts: \(billsCount)")
                        }

                        // Затем закрываем экран
                        viewModel.editingReceipt = nil
                        viewModel.showBillEntry = false
                    }
                }
                case .eventDetail(let id):
                    EventDetailView(
                        viewModel: EventDetailViewModel(
                            eventId: id,
                            service: viewModel.service,
                            receiptsRepository: receiptsRepository
                        ),
                        onAddReceipt: { viewModel.handle(.addReceiptTapped(id)) },
                        onReceiptTap: { receiptId in
                            viewModel.handle(.receiptTapped(eventId: id, receiptId: receiptId))
                        }
                    )
                }
            }
        }
        .fullScreenCover(item: $viewModel.billEntryDestination) { destination in
            BillEntryView(
                mode: destination.mode,
                eventsRepository: eventsRepository,
                receiptsRepository: receiptsRepository,
                networkMonitor: networkMonitor
            )
        }
    }
}

#Preview {
    EventsNavigationView(
        service: EventManagementService(eventsRepository: EventsDataRepository()),
        eventsRepository: EventsDataRepository(),
        receiptsRepository: ReceiptsDataRepository(),
        networkMonitor: .shared
    )
}
