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
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid server response"
        case .httpError(let statusCode, let detail):
            return "HTTP error \(statusCode): \(detail ?? "Unknown error")"
        case .decodingError(let error):
            return "Decoding error: \(error.localizedDescription)"
        case .unauthorized:
            return "Unauthorized – please log in again"
        case .noData:
            return "No data received from server"
        case .noRefreshToken:
            return "No refresh token available"
        }
    }
}
