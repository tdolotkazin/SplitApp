//
//  DeleteTransition.swift
//  SplitApp
//
//  Created by Claude Code
//

import SwiftUI

struct DeleteTransitionModifier: ViewModifier {
    let isDeleting: Bool

    @State private var rotationAngle: Double = 0

    func body(content: Content) -> some View {
        content
            .opacity(isDeleting ? 0 : 1)
            .scaleEffect(isDeleting ? 0.7 : 1.0, anchor: .trailing)
            .offset(x: isDeleting ? -400 : 0)
            .rotationEffect(.degrees(isDeleting ? rotationAngle : 0), anchor: .trailing)
            .blur(radius: isDeleting ? 8 : 0)
            .animation(.spring(response: 0.45, dampingFraction: 0.75), value: isDeleting)
            .onChange(of: isDeleting) { oldValue, newValue in
                if newValue {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        rotationAngle = -5
                    }
                }
            }
    }
}

extension View {
    func deleteTransition(isDeleting: Bool) -> some View {
        modifier(DeleteTransitionModifier(isDeleting: isDeleting))
    }
}
