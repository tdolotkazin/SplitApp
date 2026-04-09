import Foundation
import Combine

@MainActor
final class EventsNavigationViewModel: ObservableObject {
    @Published var path: [EventsNavigationRoute] = []
    @Published var showBillEntry = false
    @Published var editingReceipt: ReceiptDTO?

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

    @MainActor
    convenience init(
        service: EventManagementServiceProtocol? = nil,
        rules: EventsNavigationRules? = nil
    ) {
        let resolvedService = service ?? EventManagementService()
        let resolvedRules = rules ?? EventsNavigationRules()
        self.init(
            homeViewModel: EventsHomeViewModel(service: resolvedService),
            scannerViewModel: ReceiptViewModel(),
            rules: resolvedRules
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
        case .eventPicker:
            path.append(.eventPicker)
        }
    }

    func openReceiptForEdit(_ receipt: ReceiptDTO) {
        editingReceipt = receipt
        showBillEntry = true
    }
}
