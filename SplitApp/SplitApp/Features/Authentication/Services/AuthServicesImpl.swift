//
//  AuthServicesImpl.swift
//  SplitApp
//
//  Created by Valentina Dorina on 06.04.2026.
//


import Foundation
import UIKit

final class AuthServicesImpl: AuthService {

    private let repository: AuthRepository

    init(repository: AuthRepository) {
            self.repository = repository
        }


    func login(provider: AuthProvider, vc: UIViewController) async throws {
        let user = try await repository.login(provider: provider, vc: vc)

        // тут можно:
        // сохранить токен
        // отправить на backend
        // закешировать

    }
}
