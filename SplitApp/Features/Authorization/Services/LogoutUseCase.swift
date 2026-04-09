import Foundation
import YandexLoginSDK

final class LogoutUseCase {
    private let secureStorage: SecureStorage
    private let appState: AppState

    init(secureStorage: SecureStorage, appState: AppState) {
        self.secureStorage = secureStorage
        self.appState = appState
    }

    @MainActor
    func execute() {
        TokenStore.shared.accessToken = nil
        secureStorage.delete("refresh_token")

        do {
            try YandexLoginSDK.shared.logout()
        } catch {
            print("Ошибка logout SDK: \(error)")
        }

        appState.isLoggedIn = false
    }
}
