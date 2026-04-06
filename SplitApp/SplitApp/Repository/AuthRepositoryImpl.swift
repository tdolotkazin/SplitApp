//
//  AuthRepositoryImpl.swift
//  SplitApp
//
//  Created by Valentina Dorina on 06.04.2026.
//

import UIKit
import Foundation

final class AuthRepositoryImpl: AuthRepository {

    private let yandex: YandexAuthProvider
    //private let google: GoogleAuthProvider

    init(
        yandex: YandexAuthProvider,
       // google: GoogleAuthProvider
    ) {
        self.yandex = yandex
        //self.google = google
    }

    func login(provider: AuthProvider, vc: UIViewController) async throws {
        switch provider {
        case .yandex:
            return try await yandex.login(vc: vc)
       // case .google:
                //   return try await google.login(vc: vc)
        case .apple:
            fatalError("not implemented")
        }
    }
}
