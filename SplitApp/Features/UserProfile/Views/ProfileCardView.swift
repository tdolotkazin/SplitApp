import SwiftUI

struct ProfileCardView: View {
    let initials: String
    let name: String
    let email: String

    private let avatarURL = CurrentUserStore.shared.user.avatarURL

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
        AsyncImage(url: avatarURL) { phase in
            Group {
                if case .success(let image) = phase {
                    image
                        .resizable()
                        .scaledToFill()
                } else {
                    Circle()
                        .fill(AppTheme.accent.opacity(0.6))
                        .overlay {
                            Text(initials)
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                        }
                }
            }
        }
        .frame(width: 72, height: 72)
        .clipShape(Circle())
        .overlay(
            Circle()
                .stroke(AppTheme.avatarStroke, lineWidth: 1)
        )
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
