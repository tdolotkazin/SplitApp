import Combine
import Foundation

@MainActor
final class EventsNavigationViewModel: ObservableObject {
    @Published var path: [EventsNavigationRoute] = []
    @Published var billEntryDestination: BillEntryDestination?

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
        service: EventManagementServiceProtocol,
        rules: EventsNavigationRules
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
        switch action {
        case .addButtonTapped:
            billEntryDestination = .create(eventId: homeViewModel.currentEvent?.id)
        case .receiptTapped(let eventId, let receiptId):
            billEntryDestination = .edit(eventId: eventId, receiptId: receiptId)
        case .scannerCaptureCompleted:
            guard billEntryDestination == nil else { return }
            let billItems = scannerViewModel.items.map {
                BillItem(name: $0.name, amount: $0.amount)
            }
            billEntryDestination = .create(
                eventId: homeViewModel.currentEvent?.id,
                scannedItems: billItems,
                receiptImageJPEGData: scannerViewModel.scannedReceiptImageJPEGData
            )
        default:
            break
        }

        if let route = rules.route(for: action) {
            open(route)
        }
    }

    func didFinishBillEntry() {
        billEntryDestination = nil
        path.removeAll()
    }

    private func open(_ route: EventsNavigationRoute) {
        switch route {
        case .scanner:
            path.append(.scanner)
        case .eventPicker:
            path.append(.eventPicker)
        }
    }
}
