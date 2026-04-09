import PhotosUI
import SwiftUI

@MainActor
@Observable
final class ReceiptViewModel {
    var items: [ScannedReceiptItem] = []
    var scannedReceiptImageJPEGData: Data?
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

    /// Called by ScannerView when a captured image is ready
    func process(image: UIImage) async {
        isScanning = true
        errorMessage = nil
        scannedReceiptImageJPEGData = image.jpegData(compressionQuality: 0.85)
        defer { isScanning = false }

        do {
            let lines = try await scanner.recognizeText(in: image)
            items = parser.parse(lines: lines)
            if items.isEmpty {
                errorMessage = "Не удалось распознать чек"
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func process(photo: PhotosPickerItem) async {
        guard let data = try? await photo.loadTransferable(type: Data.self),
              let image = UIImage(data: data) else { return }
        scannedReceiptImageJPEGData = image.jpegData(compressionQuality: 0.85)
        await process(image: image)
    }

    private func loadFromPhoto() async {
        guard let photo = selectedPhoto else { return }
        selectedPhoto = nil
        await process(photo: photo)
    }
}
