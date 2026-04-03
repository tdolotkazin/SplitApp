import SwiftUI
import PhotosUI

@MainActor
@Observable
final class ReceiptViewModel {

    var items: [ReceiptItem] = []
    var isScanning = false
    var errorMessage: String?
    var selectedPhoto: PhotosPickerItem? {
        didSet { Task { await loadFromPhoto() } }
    }

    private let scanner = ReceiptScannerService()
    private let parser = ReceiptParserService()

    var total: Decimal {
        items.reduce(0) { $0 + $1.amount }
    }

    // Called by ScannerView when a captured image is ready
    func process(image: UIImage) async {
        isScanning = true
        errorMessage = nil
        defer { isScanning = false }

        do {
            let lines = try await scanner.recognizeText(in: image)
            items = parser.parse(lines: lines)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func process(photo: PhotosPickerItem) async {
        guard let data = try? await photo.loadTransferable(type: Data.self),
              let image = UIImage(data: data) else { return }
        await process(image: image)
    }

    private func loadFromPhoto() async {
        guard let photo = selectedPhoto else { return }
        await process(photo: photo)
    }
}
