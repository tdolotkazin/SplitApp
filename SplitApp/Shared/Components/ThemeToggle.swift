
import SwiftUI

struct ThemeToggle: View {
    @ObservedObject var themeManager = ThemeManager.shared

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: themeManager.currentTheme == .light ? "sun.max.fill" : "moon.fill")
                .font(.system(size: 20))
                .foregroundStyle(AppTheme.accent)

            Text(themeManager.currentTheme.rawValue)
                .font(AppTheme.fontBodyBold)
                .foregroundStyle(AppTheme.textPrimary)

            Spacer()

            // Toggle переключатель
            Toggle("", isOn: Binding(
                get: { themeManager.currentTheme == .dark },
                set: { _ in
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        themeManager.toggleTheme()
                    }
                }
            ))
            .labelsHidden()
            .tint(AppTheme.accent)
        }
        .padding(16)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                .stroke(AppTheme.cardBorder, lineWidth: 1)
        )
    }
}

// MARK: - Вариант с кнопкой
struct ThemeToggleButton: View {
    @ObservedObject var themeManager = ThemeManager.shared

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                themeManager.toggleTheme()
            }
        }) {
            Image(systemName: themeManager.currentTheme == .light ? "moon.fill" : "sun.max.fill")
                .font(.system(size: 20))
                .foregroundStyle(AppTheme.accent)
                .frame(width: 44, height: 44)
                .background(AppTheme.cardBackground)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(AppTheme.cardBorder, lineWidth: 1)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    VStack(spacing: 20) {
        ThemeToggle()
        ThemeToggleButton()
    }
    .padding()
    .background(AppTheme.backgroundGradient)
}
