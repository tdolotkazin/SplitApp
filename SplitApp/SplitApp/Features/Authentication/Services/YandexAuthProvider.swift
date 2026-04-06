//
//  YandexAuthProvider.swift
//  SplitApp
//
//  Created by Valentina Dorina on 06.04.2026.
//

import UIKit


protocol YandexAuthProvider {
    func login(vc: UIViewController) async throws
}
