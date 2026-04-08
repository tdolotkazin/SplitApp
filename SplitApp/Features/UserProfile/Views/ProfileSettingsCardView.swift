import SwiftUI

struct ProfileSettingsCardView: View {
    @Binding var notificationsEnabled: Bool

    var body: some View {
        VStack(spacing: 0) {
            notifications
            settings
        }
        .background(.ultraThinMaterial)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLarge))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLarge)
                .stroke(AppTheme.cardBorder, lineWidth: 1)
        )
        .shadow(color: AppTheme.cardShadow, radius: 10, x: 0, y: 5)
    }

    private var notifications: some View {
        VStack(spacing: 0) {
            ProfileSettingsRowView(
                icon: "bell",
                title: "Уведомления",
                iconColor: .teal,
                iconBackgroundColor: Color.teal.opacity(0.15)
            ) {
                Toggle("", isOn: $notificationsEnabled)
                    .labelsHidden()
                    .tint(AppTheme.accent)
            }
            Rectangle()
                .fill(AppTheme.dividerHighlight)
                .frame(height: 1)
                .padding(.leading, 68)
        }
    }

    private var settings: some View {
        ProfileSettingsRowView(
            icon: "rectangle.portrait.and.arrow.right",
            title: "Выйти",
            iconColor: .red,
            iconBackgroundColor: Color.red.opacity(0.12)
        ) {
            Image(systemName: "chevron.right")
                .foregroundStyle(AppTheme.textTertiary)
        }
    }
}
