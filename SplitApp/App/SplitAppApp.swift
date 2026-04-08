import SwiftUI
import YandexLoginSDK

@main
struct SplitAppApp: App {

    @StateObject private var appState = AppState()
    private let viewModel: AuthViewModel

    init() {
        do {
            try YandexLoginSDK.shared.activate(with: "dfb7a885631f4941bbdc5eb706196fa3")
        } catch {
            print("Ошибка SDK: \(error)")
        }

        // DI
        let vcProvider = DefaultViewControllerProvider()
        let storage = KeychainStorage()
        let yandexProvider = YandexAuthProviderImpl(vcProvider: vcProvider)
        let repository = AuthRepositoryImpl(yandex: yandexProvider)
        let serviceBackend = AuthServiceBackend()
        let service = AuthServicesImpl(
            repository: repository,
            serviceBackend: serviceBackend, secureStorage: storage
        )

        let useCase = LoginUseCase(
            service: service,
            secureStorage: storage
        )

        self.viewModel = AuthViewModel(
            vcProvider: vcProvider,
            useCase: useCase
        )
    }

    var body: some Scene {
        WindowGroup {

            Group {
                if appState.isLoading {
                    ProgressView()
                } else if appState.isLoggedIn {
                    BottomTabBarView(appState: appState)
                } else {
                    LoginView(viewModel: viewModel)
                        .environmentObject(appState)
                        .onOpenURL { url in
                            do {
                                try YandexLoginSDK.shared.handleOpenURL(url)
                            } catch {
                                print("SDK error: \(error)")
                            }
                        }
                }
            }
            .task {
                await bootstrap()
            }
        }
    }


    private func bootstrap() async {
        let storage = KeychainStorage()

        guard storage.get("refresh_token") != nil else {
            await MainActor.run {
                appState.isLoading = false
            }
            return
        }

        do {
            try await APIClient.shared.refreshToken()

            await MainActor.run {
                appState.isLoggedIn = true
                appState.isLoading = false
            }

        } catch {
            storage.delete("refresh_token")

            await MainActor.run {
                appState.isLoggedIn = false
                appState.isLoading = false
            }
        }
    }
}
