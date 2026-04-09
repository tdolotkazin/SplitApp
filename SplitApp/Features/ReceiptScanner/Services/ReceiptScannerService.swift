import UIKit
import Vision

/// Extracts raw text lines from a receipt image using on-device OCR.
final class ReceiptScannerService {
    /// Recognizes text in the given image and returns lines of text.
    func recognizeText(in image: UIImage) async throws -> [String] {
        guard let cgImage = image.cgImage else {
            throw ScannerError.invalidImage
        }

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                let lines = (request.results as? [VNRecognizedTextObservation] ?? [])
                    .compactMap { $0.topCandidates(1).first?.string }

                continuation.resume(returning: lines)
            }

            // Use accurate mode for receipts — slower but more precise
            request.recognitionLevel = .accurate
            request.recognitionLanguages = ["ru-RU", "en-US"]
            request.usesLanguageCorrection = true

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    enum ScannerError: LocalizedError {
        case invalidImage

        var errorDescription: String? {
            switch self {
            case .invalidImage: "Не удалось обработать изображение"
            }
        }
    }
}
