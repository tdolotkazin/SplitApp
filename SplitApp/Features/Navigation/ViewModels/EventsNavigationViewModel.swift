import Foundation
import Combine

@MainActor
final class EventsNavigationViewModel: ObservableObject {
    @Published var path: [EventsNavigationRoute] = []

    let homeViewModel: EventsHomeViewModel
    let scannerViewModel: ReceiptScannerViewModel
    let receiptInputViewModel: ReceiptInputViewModel

    private let rules: EventsNavigationRules

    init(
        homeViewModel: EventsHomeViewModel,
        scannerViewModel: ReceiptScannerViewModel,
        receiptInputViewModel: ReceiptInputViewModel,
        rules: EventsNavigationRules
    ) {
        self.homeViewModel = homeViewModel
        self.scannerViewModel = scannerViewModel
        self.receiptInputViewModel = receiptInputViewModel
        self.rules = rules
    }

    convenience init(
        service: EventManagementServiceProtocol = EventManagementService(),
        rules: EventsNavigationRules = .init()
    ) {
        self.init(
            homeViewModel: EventsHomeViewModel(service: service),
            scannerViewModel: ReceiptScannerViewModel(),
            receiptInputViewModel: ReceiptInputViewModel(service: service),
            rules: rules
        )
    }

    func loadInitialDataIfNeeded() async {
        await homeViewModel.loadDataIfNeeded()
        await receiptInputViewModel.loadDraftIfNeeded()
    }

    func handle(_ action: EventsNavigationAction) {
        let route = rules.route(for: action)
        open(route)
    }

    private func open(_ route: EventsNavigationRoute) {
        switch route {
        case .scanner:
            path.append(.scanner)
        case .receiptInput:
            Task {
                await receiptInputViewModel.loadDraftIfNeeded()
                receiptInputViewModel.resetDraft()
                path.append(.receiptInput)
            }
        }
    }
}
