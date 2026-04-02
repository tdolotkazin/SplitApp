//
//  AddItemButton.swift
//  SplitApp
//
//  Created by Claude Code
//

import SwiftUI

struct AddItemButton: View {
    let action: () -> Void

    @State private var isPulsing = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 20))
                Text("Добавить позицию")
                    .font(AppTheme.fontBodyBold)
            }
            .foregroundStyle(AppTheme.accent)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                    .stroke(AppTheme.accent.opacity(0.3), lineWidth: 1)
            )
            .scaleEffect(isPulsing ? 1.02 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                isPulsing = true
            }
        }
    }
}
