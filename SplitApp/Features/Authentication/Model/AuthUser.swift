//
//  AuthUser.swift
//  SplitApp
//
//  Created by Valentina Dorina on 31.03.2026.
//

import Foundation

struct AuthUser {
    let id: UUID
    let name: String

    init(name: String) {
        self.id = UUID()
        self.name = name
    }
}
