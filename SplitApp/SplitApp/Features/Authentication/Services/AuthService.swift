//
//  AuthService.swift
//  SplitApp
//
//  Created by Valentina Dorina on 06.04.2026.
//

import Foundation
import UIKit

protocol AuthService {
    func login(provider: AuthProvider, vc: UIViewController) async throws 
}



