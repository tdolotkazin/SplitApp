//
//  PositionParticipant.swift
//  SplitApp
//
//  Created by Valentina Dorina on 31.03.2026.
//

import Foundation

struct PositionParticipant {
    let userId: [User]
    let shareAmount: Int

    init(userId: [User], shareAmount: Int) {
        self.userId = userId
        self.shareAmount = shareAmount
    }
}
