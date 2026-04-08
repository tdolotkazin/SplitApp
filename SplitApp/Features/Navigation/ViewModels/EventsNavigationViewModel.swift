import Foundation
import Combine

@MainActor
final class EventsNavigationViewModel: ObservableObject {
    @Published var path: [EventsNavigationRoute] = []
    @Published var showBillEntry = false
    @Published var editingReceipt: ReceiptDTO? = nil

    let homeViewModel: EventsHomeViewModel
    let scannerViewModel: ReceiptViewModel

    private let rules: EventsNavigationRules

    init(
        homeViewModel: EventsHomeViewModel,
        scannerViewModel: ReceiptViewModel,
        rules: EventsNavigationRules
    ) {
        self.homeViewModel = homeViewModel
        self.scannerViewModel = scannerViewModel
        self.rules = rules
    }

    convenience init(
        service: EventManagementServiceProtocol = EventManagementService(),
        rules: EventsNavigationRules = .init()
    ) {
        self.init(
            homeViewModel: EventsHomeViewModel(service: service),
            scannerViewModel: ReceiptViewModel(),
            rules: rules
        )
    }

    func loadInitialDataIfNeeded() async {
        await homeViewModel.loadDataIfNeeded()
    }

    func handle(_ action: EventsNavigationAction) {
        if action == .addButtonTapped {
            ScannedReceiptStore.shared.store([])
        }

        if action == .scannerCaptureCompleted {
            let billItems = scannerViewModel.items.map {
                BillItem(name: $0.name, amount: $0.amount)
            }
            ScannedReceiptStore.shared.store(billItems)
        }

        let route = rules.route(for: action)
        open(route)
    }

    private func open(_ route: EventsNavigationRoute) {
        switch route {
        case .scanner:
            path.append(.scanner)
        case .billEntry:
            path.removeAll()
            editingReceipt = nil
            showBillEntry = true
        }
    }

    func openReceiptForEdit(_ receipt: ReceiptDTO) {
        editingReceipt = receipt
        showBillEntry = true
    }
}
