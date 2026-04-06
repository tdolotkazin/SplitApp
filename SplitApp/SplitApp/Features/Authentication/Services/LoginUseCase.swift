//
//  LoginUseCase.swift
//  SplitApp
//
//  Created by Valentina Dorina on 06.04.2026.
//

import Foundation
import UIKit

final class LoginUseCase {

    private let service: AuthService

    func execute(provider: AuthProvider, vc: UIViewController) async throws {
        return try await service.login(provider: provider, vc: vc)
    }

    init(service: AuthService) {
        self.service = service
    }
}
