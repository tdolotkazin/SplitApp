//
//  ParticipantAvatar.swift
//  SplitApp
//
//  Created by Claude Code
//

import SwiftUI

struct ParticipantAvatar: View {
    let participant: Participant
    var size: CGFloat = 32

    var body: some View {
        ZStack {
            // Градиент фона
            LinearGradient(
                colors: [
                    participant.color,
                    participant.color.opacity(0.8)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            // Инициалы
            Text(participant.initials)
                .font(.system(size: size * 0.375, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(
            Circle()
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
    }
}
