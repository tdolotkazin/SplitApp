//
//  APIClient.swift
//  SplitApp
//

import Foundation

// MARK: - SSL Bypass Delegate (TEMPORARY: DO NOT USE IN PRODUCTION)
private final class SSLBypassDelegate: NSObject, URLSessionDelegate {
    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        if let trust = challenge.protectionSpace.serverTrust {
            // ФОРСИРУЕМ доверие к сертификату (игнорируем ошибку mismatching target host name)
            completionHandler(.useCredential, URLCredential(trust: trust))
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
}

final class APIClient {

    // MARK: - Singleton

    static let shared = APIClient()

    // MARK: - Properties

    private let baseURL = URL(string: "https://splitapp.tech")!
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    // MARK: - Init

    private init() {
        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601

        self.encoder = JSONEncoder()
        self.encoder.dateEncodingStrategy = .iso8601
        
        // Временное решение: используем кастомную сессию с нашим делегатом для обхода SSL
        let configuration = URLSessionConfiguration.default
        let delegate = SSLBypassDelegate()
        self.session = URLSession(configuration: configuration, delegate: delegate, delegateQueue: nil)
    }

    // MARK: - Public Methods

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

    // MARK: - Private Helpers

    private func buildRequest(
        endpoint: Endpoint,
        body: (any Encodable)?
    ) throws -> URLRequest {
        var components = URLComponents(url: baseURL.appendingPathComponent(endpoint.path), resolvingAgainstBaseURL: false)

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

        // TODO: Replace with AuthManager.shared.token when Auth layer is implemented
        let token = "splitapp-production-token" // Оставил ваш токен
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
