import Foundation
import Combine

@MainActor
final class ProfileViewModel: ObservableObject {
    private let logoutUseCase: LogoutUseCase

    init(logoutUseCase: LogoutUseCase) {
        self.logoutUseCase = logoutUseCase
    }

    func logout() {
        logoutUseCase.execute()
    }
}
