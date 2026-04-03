import Foundation
import Combine

@MainActor
final class EventsFlowViewModel: ObservableObject {
    @Published var path: [EventRoute] = []

    let homeViewModel: EventsHomeViewModel
    let scannerViewModel: ReceiptScannerViewModel
    let receiptInputViewModel: ReceiptInputViewModel

    init(
        homeViewModel: EventsHomeViewModel,
        scannerViewModel: ReceiptScannerViewModel,
        receiptInputViewModel: ReceiptInputViewModel
    ) {
        self.homeViewModel = homeViewModel
        self.scannerViewModel = scannerViewModel
        self.receiptInputViewModel = receiptInputViewModel
    }

    convenience init() {
        let service = EventManagementService()
        self.init(
            homeViewModel: EventsHomeViewModel(service: service),
            scannerViewModel: ReceiptScannerViewModel(),
            receiptInputViewModel: ReceiptInputViewModel(service: service)
        )
    }

    func openScanner() {
        path.append(.scanner)
    }

    func openReceiptInput() {
        Task {
            await receiptInputViewModel.loadDraftIfNeeded()
            receiptInputViewModel.resetDraft()
            path.append(.receiptInput)
        }
    }

    func openReceiptInputFromScanner() {
        Task {
            await receiptInputViewModel.loadDraftIfNeeded()
            receiptInputViewModel.resetDraft()
            path.append(.receiptInput)
        }
    }
}
