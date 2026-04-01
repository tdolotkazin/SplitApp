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
        let service = MockEventManagementService()
        self.init(
            homeViewModel: .mock(service: service),
            scannerViewModel: ReceiptScannerViewModel(),
            receiptInputViewModel: .mock(service: service)
        )
    }

    func openScanner() {
        path.append(.scanner)
    }

    func openReceiptInput() {
        receiptInputViewModel.resetDraft()
        path.append(.receiptInput)
    }

    func openReceiptInputFromScanner() {
        receiptInputViewModel.resetDraft()
        path.append(.receiptInput)
    }
}
