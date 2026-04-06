import SwiftUI
import UIKit

enum AppTheme {
    private static func dynamicColor(light: String, dark: String) -> Color {
        Color(
            uiColor: UIColor { traitCollection in
                let hex = traitCollection.userInterfaceStyle == .dark ? dark : light
                return UIColor(Color(hex: hex))
            }
        )
    }

    static var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [
                dynamicColor(light: "#F8F9FA", dark: "#0C1015"),
                dynamicColor(light: "#E9ECEF", dark: "#11161C"),
                dynamicColor(light: "#DEE2E6", dark: "#151B22")
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var backgroundRadialGlow: RadialGradient {
        RadialGradient(
            colors: [
                dynamicColor(light: "#147CB342", dark: "#100E4A62"),
                .clear
            ],
            center: .center,
            startRadius: 100,
            endRadius: 400
        )
    }

    static var accent: Color {
        dynamicColor(light: "#7CB342", dark: "#B8FF00")
    }

    static var accentDark: Color {
        dynamicColor(light: "#558B2F", dark: "#9DDE00")
    }

    static var accentGradient: LinearGradient {
        LinearGradient(
            colors: [
                dynamicColor(light: "#7CB342", dark: "#C5FF1A"),
                dynamicColor(light: "#689F38", dark: "#A4E400")
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    static var accentForeground: Color {
        dynamicColor(light: "#FFFFFF", dark: "#11170C")
    }

    static var textPrimary: Color {
        dynamicColor(light: "#212529", dark: "#F2F3F5")
    }

    static var textSecondary: Color {
        dynamicColor(light: "#495057", dark: "#A6B4BAC4")
    }

    static var textTertiary: Color {
        dynamicColor(light: "#6C757D", dark: "#7A8E949E")
    }

    static var cardBackground: Color {
        dynamicColor(light: "#E6FFFFFF", dark: "#A62A3441")
    }

    static var cardBorder: Color {
        dynamicColor(light: "#DEE2E6", dark: "#33FFFFFF")
    }

    static var cardShadow: Color {
        dynamicColor(light: "#14000000", dark: "#66000000")
    }

    static var surfaceOverlay: Color {
        dynamicColor(light: "#0D000000", dark: "#14FFFFFF")
    }

    static var inputBackground: Color {
        dynamicColor(light: "#0F000000", dark: "#14FFFFFF")
    }

    static var inputBackgroundFocused: Color {
        dynamicColor(light: "#1A000000", dark: "#1FFFFFFF")
    }

    static var dividerHighlight: Color {
        dynamicColor(light: "#24000000", dark: "#26FFFFFF")
    }

    static var avatarStroke: Color {
        dynamicColor(light: "#33FFFFFF", dark: "#33FFFFFF")
    }

    static let cornerRadius: CGFloat = 16
    static let cornerRadiusSmall: CGFloat = 10
    static let cornerRadiusLarge: CGFloat = 24

    static let paddingSmall: CGFloat = 8
    static let paddingMedium: CGFloat = 16
    static let paddingLarge: CGFloat = 20

    static let fontHeader: Font = .system(size: 15, weight: .semibold, design: .rounded)
    static let fontBody: Font = .system(size: 17, weight: .regular, design: .rounded)
    static let fontBodyBold: Font = .system(size: 17, weight: .semibold, design: .rounded)
    static let fontTitle: Font = .system(size: 21, weight: .bold, design: .rounded)
    static let fontLargeTitle: Font = .system(size: 28, weight: .bold, design: .rounded)
}
