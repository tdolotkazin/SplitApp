import Combine
import SwiftUI
import YandexLoginSDK

@MainActor
final class AuthViewModel: ObservableObject {
    private let vcProvider: ViewControllerProvider
    private let useCase: LoginUseCase

    init(
        vcProvider: ViewControllerProvider,
        useCase: LoginUseCase

    ) {
        self.vcProvider = vcProvider
        self.useCase = useCase
    }

    func login() async -> Bool {
        guard let viewContollerProvider = vcProvider.rootViewController else {
            return false
        }

        do {
            _ = try await useCase.execute(provider: .yandex, viewContollerProvider: viewContollerProvider)
            return true
        } catch {
            print(error)
            return false
        }
    }
}
