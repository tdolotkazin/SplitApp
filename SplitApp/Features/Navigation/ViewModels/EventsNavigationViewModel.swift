import Foundation
import Combine

@MainActor
final class EventsNavigationViewModel: ObservableObject {
    @Published var path: [EventsNavigationRoute] = []
    @Published var showBillEntry = false

    let homeViewModel: EventsHomeViewModel
    let scannerViewModel: ReceiptViewModel
    let receiptInputViewModel: ReceiptInputViewModel

    private let rules: EventsNavigationRules

    init(
        homeViewModel: EventsHomeViewModel,
        scannerViewModel: ReceiptViewModel,
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
            scannerViewModel: ReceiptViewModel(),
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
        case .billEntry:
            let billItems = scannerViewModel.items.map {
                BillItem(name: $0.name, amount: $0.amount)
            }
            ScannedReceiptStore.shared.store(billItems)
            path.removeAll()        // убираем камеру со стека
            showBillEntry = true
        }
    }
}
