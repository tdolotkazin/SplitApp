import SwiftUI

struct ProfileSettingsCardView: View {
    @Binding var notificationsEnabled: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            notifications
            settings
        }
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }
    
    private var notifications: some View {
        VStack {
            ProfileSettingsRowView(
                icon: "bell",
                title: "Уведомления",
                iconColor: .teal,
                iconBackgroundColor: Color.teal.opacity(0.12)
            ) {
                Toggle("", isOn: $notificationsEnabled)
                    .labelsHidden()
                    .tint(.green)
            }
            Divider()
                .padding(.leading, 68)
            
        }
    }
    
    private var settings: some View {
        ProfileSettingsRowView(
            icon: "rectangle.portrait.and.arrow.right",
            title: "Выйти",
            titleColor: .black,
            iconColor: .red,
            iconBackgroundColor: Color.red.opacity(0.12)
        ) {
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
    }
}
