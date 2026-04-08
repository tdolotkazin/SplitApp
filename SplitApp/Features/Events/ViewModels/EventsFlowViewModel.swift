import SwiftUI
import Combine

@MainActor
final class EventsFlowViewModel: ObservableObject {
    @Published var path: [EventRoute] = []
    @Published var showCamera: Bool = false
    @Published var showPhotoPicker: Bool = false
    private(set) var pendingImage: UIImage?

    let homeViewModel: EventsHomeViewModel
    let receiptInputViewModel: ReceiptInputViewModel

    init(service: EventManagementServiceProtocol = EventManagementService()) {
        self.homeViewModel = EventsHomeViewModel(service: service)
        self.receiptInputViewModel = ReceiptInputViewModel(service: service)
    }

    func openReceiptInput() {
        path.append(.receiptInput)
    }

    func storeCapturedImage(_ image: UIImage) {
        pendingImage = image
        showCamera = false
    }

    func handlePendingImage() {
        guard let image = pendingImage else { return }
        pendingImage = nil
        path.append(.receiptInput)
        Task { await receiptInputViewModel.processImage(image) }
    }
}
