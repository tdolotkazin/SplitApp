import Foundation

extension APIClient {

    /// POST /api/users
    func createUser(_ request: CreateUserRequest) async throws -> UserDTO {
        try await self.request(endpoint: CreateUserEndpoint(), body: request)
    }
}
