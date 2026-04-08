import Foundation

final class APIClient {

    static let shared = APIClient()

    private let baseURL = URL(string: "https://splitapp.tech")!
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    private init() {
        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)

            let manualFormatter = DateFormatter()
            manualFormatter.locale = Locale(identifier: "en_US_POSIX")
            manualFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
            manualFormatter.timeZone = TimeZone(identifier: "UTC")

            if let date = manualFormatter.date(from: dateString) {
                return date
            }

            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date")
        }

        self.encoder = JSONEncoder()
        self.encoder.dateEncodingStrategy = .iso8601

        self.session = URLSession(configuration: .default)
    }

    /// Perform a request that returns a decoded response body.
    func request<T: Decodable>(
        endpoint: Endpoint,
        body: (any Encodable)? = nil
    ) async throws -> T {
        let urlRequest = try buildRequest(endpoint: endpoint, body: body)
        let (data, response) = try await session.data(for: urlRequest)

        try validateResponse(response, data: data)

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw NetworkError.decodingError(error)
        }
    }

    /// Perform a request that expects no response body (e.g. 204 No Content).
    func requestVoid(
        endpoint: Endpoint,
        body: (any Encodable)? = nil
    ) async throws {
        let urlRequest = try buildRequest(endpoint: endpoint, body: body)
        let (data, response) = try await session.data(for: urlRequest)

        try validateResponse(response, data: data)
    }

    private func buildRequest(
        endpoint: Endpoint,
        body: (any Encodable)?
    ) throws -> URLRequest {
        var components = URLComponents(
            url: baseURL.appendingPathComponent(endpoint.path),
            resolvingAgainstBaseURL: false)

        if let queryItems = endpoint.queryItems {
            components?.queryItems = queryItems
        }

        guard let url = components?.url else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let token = "splitapp-production-token"
        if !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body {
            request.httpBody = try encoder.encode(body)
        }

        return request
    }

    private func validateResponse(_ response: URLResponse, data: Data) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200...299:
            return
        case 401:
            throw NetworkError.unauthorized
        default:
            let detail = try? decoder.decode(ErrorResponseDTO.self, from: data).detail
            throw NetworkError.httpError(statusCode: httpResponse.statusCode, detail: detail)
        }
    }
}
