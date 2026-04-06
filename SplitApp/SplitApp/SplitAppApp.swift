//
//  SplitAppApp.swift
//  SplitApp
//
//  Created by Valentina Dorina on 31.03.2026.
//

import SwiftUI
import CoreData
import YandexLoginSDK


/*
@main
struct SplitAppApp: App {
    let persistenceController = PersistenceController.shared

    init() {
        do {
            try YandexLoginSDK.shared.activate(with: "dfb7a885631f4941bbdc5eb706196fa3")
        } catch {
            print("Ошибка активации Яндекс SDK: \(error)")
        }
    }


    var body: some Scene {
        WindowGroup {
            AppleSignInView()

                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
*/

@main
struct SplitAppApp: App {

    private let viewModel: AuthViewModel
    let persistenceController = PersistenceController.shared

    init() {
        do {
            try YandexLoginSDK.shared.activate(with: "dfb7a885631f4941bbdc5eb706196fa3")
        } catch {
            print("Ошибка активации Яндекс SDK: \(error)")
        }

        // 🔥 DI сборка
        let vcProvider = DefaultViewControllerProvider()
        let yandexProvider = YandexAuthProviderImpl(vcProvider: vcProvider)
        let repository = AuthRepositoryImpl(yandex: yandexProvider)
        let service = AuthServicesImpl(repository: repository)
        let useCase = LoginUseCase(service: service)

        let vm = AuthViewModel(vcProvider: vcProvider, useCase: useCase)

        self.viewModel = AuthViewModel(vcProvider: vcProvider, useCase: useCase)
    }

    var body: some Scene {
        WindowGroup {
            LoginView(viewModel: viewModel)
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
