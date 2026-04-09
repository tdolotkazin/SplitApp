import SwiftUI

struct FriendRowView: View {
    let friend: Friend

    var body: some View {
        HStack(spacing: 12) {
            FriendAvatar(friend: friend, size: 56)

            VStack(alignment: .leading, spacing: 4) {
                Text(friend.name)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)

                Text("Всё закрыто")
                    .font(.system(size: 15, weight: .regular, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                .stroke(AppTheme.cardBorder, lineWidth: 1)
        )
    }
}
