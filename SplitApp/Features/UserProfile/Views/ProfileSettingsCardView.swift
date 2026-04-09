import SwiftUI

struct ProfileSettingsCardView: View {
    @Binding var notificationsEnabled: Bool
    @ObservedObject var viewModel: ProfileViewModel

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
        Button {
            viewModel.logout()
        } label: {
            HStack {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .foregroundColor(.red)
                    .frame(width: 32, height: 32)
                    .background(Color.red.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                Text("Выйти")
                    .foregroundColor(.black)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }
            .padding()
        }
    }
}
