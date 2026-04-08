import SwiftUI

struct ProfileSettingsCardView: View {
    @Binding var notificationsEnabled: Bool

    var body: some View {
        GlassCard(padding: 0) {
            VStack(spacing: 0) {
                notifications
                settings
            }
        }
    }

    private var notifications: some View {
        VStack(spacing: 0) {
            ProfileSettingsRowView(
                icon: "bell",
                title: "Уведомления",
                iconColor: .teal,
                iconBackgroundColor: Color.teal.opacity(0.12)
            ) {
                Toggle("", isOn: $notificationsEnabled)
                    .labelsHidden()
                    .tint(AppTheme.accent)
            }
            AppTheme.dividerHighlight
                .frame(height: 0.5)
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
