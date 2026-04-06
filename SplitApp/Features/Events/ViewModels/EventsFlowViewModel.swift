import Foundation
import Combine
import UIKit

@MainActor
final class EventsFlowViewModel: ObservableObject {
    @Published var path: [EventRoute] = []
    @Published var showScanOptions = false
    @Published var showCamera = false
    @Published var showPhotoPicker = false
    @Published var showBillEntry = false

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

    func openScanOptions() {
        showScanOptions = true
    }

    func didCaptureImage(_ image: UIImage) async {
        await scannerViewModel.process(image: image)
        await openReceiptInputFromScanner()
    }

    func openReceiptInput() {
        Task {
            await receiptInputViewModel.loadDraftIfNeeded()
            receiptInputViewModel.resetDraft()
            path.append(.receiptInput)
        }
    }

    func openBillEntry() {
        showBillEntry = true
    }

    private func openReceiptInputFromScanner() async {
        await receiptInputViewModel.loadDraftIfNeeded()
        receiptInputViewModel.populate(from: scannerViewModel.items)
        path.append(.receiptInput)
    }
}
