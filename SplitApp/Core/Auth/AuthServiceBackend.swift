import Foundation


final class AuthServiceBackend {

    func sendTokenToBackend(token: String) async throws -> AuthResponse {
            /*let url = URL(string: "https://splitapp.tech/api/login")!

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            let body = ["yandex_token": token]
            request.httpBody = try JSONEncoder().encode(body)

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let http = response as? HTTPURLResponse else {
                throw URLError(.badServerResponse)
            }

            guard (200...299).contains(http.statusCode) else {
                throw URLError(.badServerResponse)
            }

            return try JSONDecoder().decode(AuthResponse.self, from: data)
        */
        let body = ["yandex_token": token]

                return try await APIClient.shared.request(
                    endpoint: AuthUserEndpoint(yandexToken: token),
                    body: body
                )
    }

    
}
