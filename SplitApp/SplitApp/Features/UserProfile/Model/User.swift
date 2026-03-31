//
//  User.swift
//  SplitApp
//
//  Created by Valentina Dorina on 31.03.2026.
//

import Foundation

struct User: Hashable {
    let id: UUID
    var name: String
    
    init(from authUser: AuthUser) {
        self.id = authUser.id
        self.name = authUser.name
    }
}
