import SwiftUI

struct EventsFlowView: View {
    @StateObject private var viewModel = EventsFlowViewModel()

    var body: some View {
        NavigationStack(path: $viewModel.path) {
            EventsHomeView(
                viewModel: viewModel.homeViewModel,
                onScanTap: viewModel.openScanner,
                onAddTap: viewModel.openReceiptInput
            )
            .task {
                await viewModel.homeViewModel.loadDataIfNeeded()
                await viewModel.receiptInputViewModel.loadDraftIfNeeded()
            }
            .navigationDestination(for: EventRoute.self) { route in
                switch route {
                case .scanner:
                    ReceiptScannerView(
                        viewModel: viewModel.scannerViewModel,
                        onCapture: viewModel.openReceiptInputFromScanner
                    )
                    .navigationBarBackButtonHidden(true)
                case .receiptInput:
                    ReceiptInputView(viewModel: viewModel.receiptInputViewModel)
                        .navigationBarBackButtonHidden(true)
                }
            }
        }
    }
}

#Preview {
    EventsFlowView()
}
