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
                onAddTap: { viewModel.handle(.addButtonTapped) }
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
                case .receiptInput:
                    ReceiptInputView(viewModel: viewModel.receiptInputViewModel)
                        .navigationBarBackButtonHidden(true)
                case .billEntry:
                    EmptyView()
                }
            }
        }
        .fullScreenCover(isPresented: $viewModel.showBillEntry) {
            BillEntryView()
        }
    }
}

#Preview {
    EventsNavigationView()
}
