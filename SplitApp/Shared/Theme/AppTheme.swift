
import SwiftUI

enum AppTheme {
    // MARK: - Dynamic Theme Properties
    static func backgroundGradient(for theme: ThemeMode) -> LinearGradient {
        switch theme {
        case .light:
            return LinearGradient(
                colors: [
                    Color(hex: "#F8F9FA"),
                    Color(hex: "#E9ECEF"),
                    Color(hex: "#DEE2E6")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .dark:
            return LinearGradient(
                colors: [
                    Color(hex: "#0A0F1A"),
                    Color(hex: "#111827"),
                    Color(hex: "#1A2035")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    static func backgroundRadialGlow(for theme: ThemeMode) -> RadialGradient {
        let color = theme == .light ? Color(hex: "#7CB342") : Color(hex: "#C8FF00")
        let opacity = theme == .light ? 0.08 : 0.05

        return RadialGradient(
            colors: [
                color.opacity(opacity),
                Color.clear
            ],
            center: .center,
            startRadius: 100,
            endRadius: 400
        )
    }

    static func accent(for theme: ThemeMode) -> Color {
        theme == .light ? Color(hex: "#7CB342") : Color(hex: "#C8FF00")
    }

    static func accentDark(for theme: ThemeMode) -> Color {
        theme == .light ? Color(hex: "#558B2F") : Color(hex: "#9ECC00")
    }

    static func accentGradient(for theme: ThemeMode) -> LinearGradient {
        switch theme {
        case .light:
            return LinearGradient(
                colors: [Color(hex: "#7CB342"), Color(hex: "#689F38")],
                startPoint: .leading,
                endPoint: .trailing
            )
        case .dark:
            return LinearGradient(
                colors: [Color(hex: "#C8FF00"), Color(hex: "#A8E600")],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
    }

    static func textPrimary(for theme: ThemeMode) -> Color {
        theme == .light ? Color(hex: "#212529") : Color.white
    }

    static func textSecondary(for theme: ThemeMode) -> Color {
        theme == .light ? Color(hex: "#495057") : Color.white.opacity(0.6)
    }

    static func textTertiary(for theme: ThemeMode) -> Color {
        theme == .light ? Color(hex: "#6C757D") : Color.white.opacity(0.35)
    }

    static func cardBackground(for theme: ThemeMode) -> Color {
        theme == .light ? Color.white.opacity(0.9) : Color.white.opacity(0.08)
    }

    static func cardBorder(for theme: ThemeMode) -> Color {
        theme == .light ? Color(hex: "#DEE2E6") : Color.white.opacity(0.12)
    }

    static func cardShadow(for theme: ThemeMode) -> Color {
        theme == .light ? Color.black.opacity(0.08) : Color.black.opacity(0.3)
    }

    // MARK: - Статические свойства для обратной совместимости
    // Используют текущую тему из ThemeManager
    static var backgroundGradient: LinearGradient {
        backgroundGradient(for: ThemeManager.shared.currentTheme)
    }

    static var backgroundRadialGlow: RadialGradient {
        backgroundRadialGlow(for: ThemeManager.shared.currentTheme)
    }

    static var accent: Color {
        accent(for: ThemeManager.shared.currentTheme)
    }

    static var accentDark: Color {
        accentDark(for: ThemeManager.shared.currentTheme)
    }

    static var accentGradient: LinearGradient {
        accentGradient(for: ThemeManager.shared.currentTheme)
    }

    static var textPrimary: Color {
        textPrimary(for: ThemeManager.shared.currentTheme)
    }

    static var textSecondary: Color {
        textSecondary(for: ThemeManager.shared.currentTheme)
    }

    static var textTertiary: Color {
        textTertiary(for: ThemeManager.shared.currentTheme)
    }

    static var cardBackground: Color {
        cardBackground(for: ThemeManager.shared.currentTheme)
    }

    static var cardBorder: Color {
        cardBorder(for: ThemeManager.shared.currentTheme)
    }

    static var cardShadow: Color {
        cardShadow(for: ThemeManager.shared.currentTheme)
    }

    // MARK: - Corner Radius (не зависят от темы)
    static let cornerRadius: CGFloat = 16
    static let cornerRadiusSmall: CGFloat = 10
    static let cornerRadiusLarge: CGFloat = 24

    // MARK: - Spacing
    static let paddingSmall: CGFloat = 8
    static let paddingMedium: CGFloat = 16
    static let paddingLarge: CGFloat = 20

    // MARK: - Typography
    static let fontHeader: Font = .system(size: 14, weight: .semibold, design: .rounded)
    static let fontBody: Font = .system(size: 16, weight: .regular, design: .rounded)
    static let fontBodyBold: Font = .system(size: 16, weight: .semibold, design: .rounded)
    static let fontTitle: Font = .system(size: 20, weight: .bold, design: .rounded)
    static let fontLargeTitle: Font = .system(size: 28, weight: .bold, design: .rounded)
}
