import SwiftUI

struct ProfileCardView: View {
    let initials: String
    let name: String
    let email: String

    var body: some View {
        GlassCard(padding: 20) {
            HStack(spacing: 16) {
                avatarCircle
                profileText
                Spacer()
            }
        }
    }

    private var avatarCircle: some View {
        Circle()
            .fill(AppTheme.accent.opacity(0.6))
            .frame(width: 72, height: 72)
            .overlay {
                Text(initials)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
            }
    }

    private var profileText: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(name)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(AppTheme.textPrimary)
            Text(email)
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)
        }
    }
}
