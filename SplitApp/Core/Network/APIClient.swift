import Foundation
import KeychainSwift

final class APIClient {

    static let shared = APIClient()

    private let secureStorage: KeychainStorage

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

            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Invalid date"
            )
        }

        self.encoder = JSONEncoder()
        self.encoder.dateEncodingStrategy = .iso8601

        self.session = URLSession(configuration: .default)
        self.secureStorage = KeychainStorage()
    }

    func request<T: Decodable>(
        endpoint: Endpoint,
        body: (any Encodable)? = nil
    ) async throws -> T {
        return try await performRequest(
            endpoint: endpoint,
            body: body,
            isRetry: false
        )
    }

    // MARK: - Core logic

    private func performRequest<T: Decodable>(
        endpoint: Endpoint,
        body: (any Encodable)?,
        isRetry: Bool
    ) async throws -> T {

        let request = try buildRequest(endpoint: endpoint, body: body)

        let (data, response) = try await session.data(for: request)

        do {
            try validateResponse(response, data: data)
            return try decoder.decode(T.self, from: data)

        } catch NetworkError.unauthorized {

            if isRetry {
                throw NetworkError.unauthorized
            }

            try await refreshToken()

            return try await performRequest(
                endpoint: endpoint,
                body: body,
                isRetry: true
            )
        }
    }

    func requestVoid(
        endpoint: Endpoint,
        body: (any Encodable)? = nil
    ) async throws {
        let urlRequest = try buildRequest(endpoint: endpoint, body: body)
        let (data, response) = try await session.data(for: urlRequest)

        try validateResponse(response, data: data)
    }

    // MARK: - Build Request

    private func buildRequest(
        endpoint: Endpoint,
        body: (any Encodable)?
    ) throws -> URLRequest {

        var components = URLComponents(
            url: baseURL.appendingPathComponent(endpoint.path),
            resolvingAgainstBaseURL: false
        )

        components?.queryItems = endpoint.queryItems

        guard let url = components?.url else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue

        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if let token = TokenStore.shared.accessToken, !token.isEmpty {
            request.setValue(
                "Bearer \(token)",
                forHTTPHeaderField: "Authorization"
            )
        }

        if let body {
            request.httpBody = try encoder.encode(body)
        }

        return request
    }

    // MARK: - Refresh Token

    func refreshToken() async throws {

        guard let refreshToken = secureStorage.get("refresh_token") else {
            throw NetworkError.unauthorized
        }

        let url = baseURL.appendingPathComponent("/api/refresh")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = ["refresh_token": refreshToken]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)

        try validateResponse(response, data: data)

        let authResponse = try decoder.decode(AuthResponse.self, from: data)

        TokenStore.shared.accessToken = authResponse.accessToken
        secureStorage.save(authResponse.refreshToken, for: "refresh_token")
    }

    // MARK: - Validate

    private func validateResponse(_ response: URLResponse, data: Data) throws {

        guard let http = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        switch http.statusCode {
        case 200...299:
            return
        case 401:
            throw NetworkError.unauthorized
        case 403:
            throw NetworkError.httpError(statusCode: 403, detail: "Forbidden")
        default:
            throw NetworkError.httpError(
                statusCode: http.statusCode,
                detail: nil
            )
        }
    }
}
