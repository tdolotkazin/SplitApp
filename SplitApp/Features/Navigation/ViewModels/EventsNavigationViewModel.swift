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
    private(set) var service: EventManagementServiceProtocol

    init(
        homeViewModel: EventsHomeViewModel,
        scannerViewModel: ReceiptViewModel,
        rules: EventsNavigationRules,
        service: EventManagementServiceProtocol
    ) {
        self.homeViewModel = homeViewModel
        self.scannerViewModel = scannerViewModel
        self.rules = rules
        self.service = service
    }

    convenience init(
        service: EventManagementServiceProtocol,
        rules: EventsNavigationRules
    ) {
        self.init(
            homeViewModel: EventsHomeViewModel(service: service),
            scannerViewModel: ReceiptViewModel(),
            rules: rules,
            service: service
        )
    }

    func loadInitialDataIfNeeded() async {
        await homeViewModel.loadDataIfNeeded()
    }

    func handle(_ action: EventsNavigationAction) {
        switch action {
        case .addButtonTapped:
            billEntryDestination = .create(eventId: nil)
        case .addReceiptTapped(let id):
            billEntryDestination = .create(eventId: id)
        case .receiptTapped(let eventId, let receiptId):
            billEntryDestination = .edit(eventId: eventId, receiptId: receiptId)
        case .scannerCaptureCompleted:
            let billItems = scannerViewModel.items.map {
                BillItem(name: $0.name, amount: $0.amount)
            }
            billEntryDestination = .create(eventId: nil, scannedItems: billItems)
        default:
            break
        }

        if let route = rules.route(for: action) {
            open(route)
        }
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
