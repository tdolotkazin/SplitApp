import SwiftUI

struct RootView: View {

    @StateObject private var appState = AppState()

    var body: some View {
        Group {
            //if appState.isLoading {
             //   ProgressView()
            //} else
            if viewModel.isLoggedIn {
                BottomTabBarView()
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
    }

    private func bootstrap() async {
        let useCase = BootstrapAuthUseCase(storage: KeychainStorage())
        let isLoggedIn = await useCase.execute()

        await MainActor.run {
            appState.isLoggedIn = isLoggedIn
            appState.isLoading = false
        }
    }
}
