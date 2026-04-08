import SwiftUI

struct EventsNavigationView: View {
    @StateObject private var viewModel: EventsNavigationViewModel

    init(
        service: EventManagementServiceProtocol = EventManagementService(),
        rules: EventsNavigationRules = .init()
    ) {
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
                            print("📱 currentEventBills.count после loadReceipts: \(viewModel.homeViewModel.currentEventBills.count)")
                        }

                        // Затем закрываем экран
                        viewModel.editingReceipt = nil
                        viewModel.showBillEntry = false
                    }
                }
            )
        }
    }
}

#Preview {
    EventsNavigationView()
}
