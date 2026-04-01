import Foundation
import Combine

@MainActor
final class ReceiptScannerViewModel: ObservableObject {
    @Published var isFlashEnabled = false

    func toggleFlash() {
        isFlashEnabled.toggle()
    }
}
