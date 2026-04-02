//
//  StaggeredAppearModifier.swift
//  SplitApp
//
//  Created by Claude Code
//

import SwiftUI

struct StaggeredAppearModifier: ViewModifier {
    let index: Int
    let delay: Double = 0.1

    @State private var appeared = false

    func body(content: Content) -> some View {
        content
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 20)
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(Double(index) * delay)) {
                    appeared = true
                }
            }
    }
}

extension View {
    func staggeredAppear(index: Int) -> some View {
        modifier(StaggeredAppearModifier(index: index))
    }
}
