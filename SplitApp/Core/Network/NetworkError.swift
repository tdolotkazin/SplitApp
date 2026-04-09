import Foundation

enum NetworkError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int, detail: String?)
    case decodingError(Error)
    case unauthorized
    case noData
    case noRefreshToken

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            "Invalid URL"
        case .invalidResponse:
            "Invalid server response"
        case let .httpError(statusCode, detail):
            "HTTP error \(statusCode): \(detail ?? "Unknown error")"
        case let .decodingError(error):
            "Decoding error: \(error.localizedDescription)"
        case .unauthorized:
            "Unauthorized – please log in again"
        case .noData:
            "No data received from server"
        case .noRefreshToken:
            "No refresh token available"
        }
    }
}
