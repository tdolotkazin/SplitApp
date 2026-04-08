import SwiftUI

struct ProfileCardView: View {
    let initials: String
    let name: String
    let email: String

    var body: some View {
        HStack(spacing: 16) {
            avatarCircleWithInitials
            profileText
            Spacer()
        }
        .padding(20)
        .background(.ultraThinMaterial)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLarge))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLarge)
                .stroke(AppTheme.cardBorder, lineWidth: 1)
        )
        .shadow(color: AppTheme.cardShadow, radius: 10, x: 0, y: 5)
    }

    private var avatarCircleWithInitials: some View {
        Circle()
            .fill(AppTheme.accent.opacity(0.2))
            .frame(width: 72, height: 72)
            .overlay {
                Text(initials)
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.accent)
            }
    }

    private var profileText: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(name)
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)
            Text(email)
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundStyle(AppTheme.textSecondary)
        }
    }
}
