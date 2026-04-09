import SwiftUI

struct ProfileCardView: View {
    let initials: String
    let name: String
    let email: String
    let avatarURL: URL?

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
                switch phase {
                case let .success(image):
                    image
                        .resizable()
                        .scaledToFill()
                case let .failure(error):
                    initialsAvatar
                        .onAppear {
                            print("❌ ProfileCardView: Failed to load avatar - \(error.localizedDescription)")
                        }
                case .empty:
                    initialsAvatar
                        .onAppear {
                            if let url = avatarURL {
                                print("📡 ProfileCardView: Loading avatar from \(url.absoluteString)")
                            } else {
                                print("⚠️ ProfileCardView: No avatar URL provided")
                            }
                        }
                @unknown default:
                    initialsAvatar
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

    private var initialsAvatar: some View {
        ZStack {
            LinearGradient(
                colors: [
                    AppTheme.accent,
                    AppTheme.accent.opacity(0.8)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            Text(initials)
                .font(.system(size: 27, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
        }
    }

    private var profileText: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(name)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(AppTheme.textPrimary)
                .lineLimit(2)
            Text(email)
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
    }
}
