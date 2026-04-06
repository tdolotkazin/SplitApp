import SwiftUI
import YandexLoginSDK
import Combine

@MainActor
final class AuthViewModel: ObservableObject {

    //@Published var user: User?
    //@Published var error: String?

    private let vcProvider: ViewControllerProvider
    private let useCase: LoginUseCase
    
    init(
            vcProvider: ViewControllerProvider,
            useCase: LoginUseCase
        ) {
            self.vcProvider = vcProvider
            self.useCase = useCase
        }

    func login() {
            guard let vc = vcProvider.rootViewController else { return }

            Task {
                try await useCase.execute(provider: .yandex, vc: vc)
            }
        }
    /*
    func login(provider: AuthProvider) {
        guard let vc = DefaultViewControllerProvider() else { return }

        Task {
            do {
                self.user = try await useCase.execute(provider: provider, vc: vc)
            } catch {
                self.error = error.localizedDescription
            }
        }
    }
     */
}
