import SwiftUI
import YandexLoginSDK

@main
struct SplitAppApp: App {
    private let dependencies = AppDependencies.live

    @StateObject private var appState = AppState()
    private let viewModel: AuthViewModel

    init() {
        do {
            try YandexLoginSDK.shared.activate(
                with: "dfb7a885631f4941bbdc5eb706196fa3"
            )
        } catch {
            print("Ошибка SDK: \(error)")
        }

        let vcProvider = DefaultViewControllerProvider()
        let storage = KeychainStorage()
        let yandexProvider = YandexAuthProviderImpl(vcProvider: vcProvider)
        let repository = AuthRepositoryImpl(yandex: yandexProvider)
        let serviceBackend = AuthServiceBackend()
        let service = AuthServicesImpl(
            repository: repository,
            serviceBackend: serviceBackend,
            secureStorage: storage
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
                    ContentView(dependencies: dependencies, appState: appState)
                } else {
                    LoginView(viewModel: viewModel)
                        .onOpenURL { url in
                            do {
                                try YandexLoginSDK.shared.handleOpenURL(url)
                                print("URL успешно передан в SDK")
                            } catch {
                                print("SDK не смог обработать URL: \(error)")
                            }
                        }
                }
            }
            .task {
                await bootstrap()
            }
            .environmentObject(appState)
        }
    }

    private func bootstrap() async {
        let storage = KeychainStorage()

        guard storage.get("refresh_token") != nil else {
            TokenStore.shared.clear()
            await MainActor.run {
                appState.isLoggedIn = false
                appState.isLoading = false
            }
            return
        }

        do {
            try await APIClient.shared.refreshAccessTokenIfNeeded()
            await MainActor.run {
                appState.isLoggedIn = true
                appState.isLoading = false
            }
        } catch {
            print("Не удалось обновить токен: \(error)")
            storage.delete("refresh_token")
            TokenStore.shared.clear()
            await MainActor.run {
                appState.isLoggedIn = false
                appState.isLoading = false
            }
        }
    }
}
