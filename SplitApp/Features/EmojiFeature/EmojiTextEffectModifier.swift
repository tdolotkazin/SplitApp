import SwiftUI
import UIKit

struct EmojiTextEffectModifier: ViewModifier {
    @Binding var text: String

    let matcher: EmojiAutoReplaceMatcher
    let onUpdate: ((String) -> Void)?

    @State private var animatedEmoji: String?
    @State private var showEmojiBurst = false

    private let haptic = UIImpactFeedbackGenerator(style: .light)

    func body(content: Content) -> some View {
        ZStack(alignment: .trailing) {
            content
                .onAppear {
                    haptic.prepare()
                }
                .onChange(of: text) { _, newValue in
                    handleTextChange(newValue)
                }

            if let animatedEmoji, showEmojiBurst {
                Text(animatedEmoji)
                    .font(.system(size: 26))
                    .scaleEffect(showEmojiBurst ? 1.0 : 0.4)
                    .offset(x: showEmojiBurst ? 0 : 10, y: showEmojiBurst ? 0 : -8)
                    .opacity(showEmojiBurst ? 1 : 0)
                    .animation(.spring(response: 0.28, dampingFraction: 0.6), value: showEmojiBurst)
                    .transition(.scale.combined(with: .opacity))
            }
        }
    }

    private func handleTextChange(_ newValue: String) {
        guard let match = matcher.match(for: newValue) else {
            onUpdate?(newValue)
            return
        }

        guard newValue != match.emoji else {
            onUpdate?(newValue)
            return
        }

        text = match.emoji
        onUpdate?(match.emoji)

        haptic.impactOccurred()
        haptic.prepare()

        playEmojiAnimation(match.emoji)
    }

    private func playEmojiAnimation(_ emoji: String) {
        animatedEmoji = emoji
        showEmojiBurst = false

        withAnimation(.spring(response: 0.28, dampingFraction: 0.6)) {
            showEmojiBurst = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
            withAnimation(.easeOut(duration: 0.2)) {
                showEmojiBurst = false
            }
        }
    }
}
