import SwiftUI

struct EmptyFriendsState: View {
    let onAddFriend: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.2.fill")
                .font(.system(size: 60))
                .foregroundStyle(AppTheme.textTertiary)
                .padding(.bottom, 8)

            Text("Нет друзей")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)

            Text("Добавьте друзей, чтобы\nначать делить расходы")
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.textSecondary)
                .multilineTextAlignment(.center)

            Button(action: onAddFriend) {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                        .font(.system(size: 15, weight: .semibold))

                    Text("Добавить друга")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                }
                .foregroundStyle(AppTheme.accentForeground)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(AppTheme.accentGradient)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.top, 8)
        }
        .padding(40)
    }
}

#Preview {
    ZStack {
        AppTheme.backgroundGradient
            .ignoresSafeArea()

        EmptyFriendsState(onAddFriend: {})
    }
}
