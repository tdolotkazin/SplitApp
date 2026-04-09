import Foundation

final class APIClient {
    static let shared = APIClient()

    private let secureStorage: KeychainStorage
    private let baseURL = URL(string: "https://splitapp.tech")!
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    private init() {
        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
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

        encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        session = URLSession(configuration: .default)
        secureStorage = KeychainStorage()
    }

    func request<T: Decodable>(
        endpoint: Endpoint,
        body: (any Encodable)? = nil
    ) async throws -> T {
        try await performRequest(
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
        if requiresAuthorization(endpoint: endpoint),
            TokenStore.shared.accessToken?.isEmpty ?? true {
            try? await refreshAccessTokenIfNeeded()
        }

        let request = try buildRequest(endpoint: endpoint, body: body)
        let (data, response) = try await session.data(for: request)

        do {
            try validateResponse(response, data: data)
            return try decoder.decode(T.self, from: data)

        } catch NetworkError.unauthorized {
            if isRetry {
                throw NetworkError.unauthorized
            }

            try await refreshAccessTokenIfNeeded()

            let retryRequest = try buildRequest(endpoint: endpoint, body: body)
            let (retryData, retryResponse) = try await session.data(
                for: retryRequest
            )

            try validateResponse(retryResponse, data: retryData)

            return try decoder.decode(T.self, from: retryData)
        }
    }

    private func requiresAuthorization(endpoint: Endpoint) -> Bool {
        endpoint.path != AuthUserEndpoint(yandexToken: "").path
            && endpoint.path != RefreshTokenEndpoint().path
    }

    func requestVoid(
        endpoint: Endpoint,
        body: (any Encodable)? = nil
    ) async throws {
        let urlRequest = try buildRequest(endpoint: endpoint, body: body)
        let (data, response) = try await session.data(for: urlRequest)

        try validateResponse(response, data: data)
    }

    func requestMultipart<T: Decodable>(
        endpoint: Endpoint,
        fileFieldName: String,
        fileName: String,
        mimeType: String,
        fileData: Data
    ) async throws -> T {
        let boundary = "Boundary-\(UUID().uuidString)"
        var request = try buildRequest(endpoint: endpoint, body: nil)
        request.setValue(
            "multipart/form-data; boundary=\(boundary)",
            forHTTPHeaderField: "Content-Type"
        )

        var body = Data()
        body.append(Data("--\(boundary)\r\n".utf8))
        body.append(
            Data(
                "Content-Disposition: form-data; name=\"\(fileFieldName)\"; filename=\"\(fileName)\"\r\n"
                    .utf8
            )
        )
        body.append(Data("Content-Type: \(mimeType)\r\n\r\n".utf8))
        body.append(fileData)
        body.append(Data("\r\n--\(boundary)--\r\n".utf8))
        request.httpBody = body

        let (data, response) = try await session.data(for: request)
        try validateResponse(response, data: data)

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw NetworkError.decodingError(error)
        }
    }

    func refreshAccessTokenIfNeeded() async throws {
        if TokenStore.shared.accessToken != nil,
            TokenStore.shared.isValid {
            return
        }

        guard let refreshToken = secureStorage.get("refresh_token") else {
            throw NetworkError.unauthorized
        }

        let body = ["refresh_token": refreshToken]

        let response: AuthResponseRefreshToken = try await performRequest(
            endpoint: RefreshTokenEndpoint(),
            body: body,
            isRetry: true
        )

        TokenStore.shared.save(token: response.accessToken)
        secureStorage.save(response.refreshToken, for: "refresh_token")
    }

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
            let detail =
                (try? decoder.decode(ErrorResponseDTO.self, from: data).detail)
                ?? response.debugDescription
            throw NetworkError.httpError(
                statusCode: http.statusCode,
                detail: detail
            )
        }
    }
}
