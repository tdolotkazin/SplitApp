//
//  AuthRepository.swift
//  SplitApp
//
//  Created by Valentina Dorina on 06.04.2026.
//

import Foundation
import UIKit

protocol AuthRepository {
    func login(provider: AuthProvider, vc: UIViewController) async throws
}
