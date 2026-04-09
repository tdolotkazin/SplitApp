import Foundation

final class AuthServiceBackend {
    func sendTokenToBackend(token: String) async throws -> AuthResponse {
        let body = ["yandex_token": token]

        return try await APIClient.shared.request(
            endpoint: AuthUserEndpoint(yandexToken: token),
            body: body
        )
    }
}
