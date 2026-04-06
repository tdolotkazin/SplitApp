//
//  YandexAuthProviderImpl.swift
//  SplitApp
//
//  Created by Valentina Dorina on 06.04.2026.
//

import Foundation
import YandexLoginSDK
import UIKit

final class YandexAuthProviderImpl: YandexAuthProvider {
    private var continuation: CheckedContinuation<User, Error>?
    private let vcProvider: ViewControllerProvider

    init(vcProvider: ViewControllerProvider) {
        self.vcProvider = vcProvider
    }

    deinit {
        YandexLoginSDK.shared.remove(observer: self)
    }



    func login(vc: UIViewController) throws {
//        try YandexLoginSDK.shared.activate(with: "dfb7a885631f4941bbdc5eb706196fa3")
        YandexLoginSDK.shared.add(observer: self)

        guard let vc = vcProvider.rootViewController else {
            throw AuthError.invalidToken
        }
       try YandexLoginSDK.shared.authorize(with: vc)
    }

    private func finishSuccess(_ user: User) {
        continuation?.resume(returning: user)
        continuation = nil
    }

    private func finishFailure(_ error: Error) {
        continuation?.resume(throwing: error)
        continuation = nil
    }


}


extension YandexAuthProviderImpl: YandexLoginSDKObserver {
    func didFinishLogin(with result: Result<LoginResult, any Error>) {
        switch result {

        case .success(let data):
            let user = User(
                id: data.jwt,
                token: data.token,
                provider: .yandex
            )
            finishSuccess(user)

        case .failure(let error):
            finishFailure(error)
        }
    }
}











/*
 return try await withCheckedThrowingContinuation { continuation in self.continuation = continuation

 do {
 try YandexLoginSDK.shared.authorize(with: vc)
 } catch {
 continuation.resume(throwing: error)
 self.continuation = nil
 }
 }*/


