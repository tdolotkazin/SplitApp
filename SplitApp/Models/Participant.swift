//
//  Participant.swift
//  SplitApp
//
//  Created by Claude Code
//

import SwiftUI

struct Participant: Identifiable, Hashable {
    let id: UUID
    var name: String
    var initials: String // "АР", "МС", "ИВ"
    var color: Color      // уникальный цвет аватара

    init(id: UUID = UUID(), name: String, initials: String, color: Color) {
        self.id = id
        self.name = name
        self.initials = initials
        self.color = color
    }
}
