import SwiftUI

struct FriendAvatar: View {
    let friend: Friend
    var size: CGFloat = 56

    var body: some View {
        AsyncImage(url: friend.avatarURL) { phase in
            Group {
                if case let .success(image) = phase {
                    image
                        .resizable()
                        .scaledToFill()
                } else {
                    initialsAvatar
                }
            }
        }
        .frame(width: size, height: size)
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
                    friend.color,
                    friend.color.opacity(0.8)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            Text(friend.initials)
                .font(.system(size: size * 0.375, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
        }
    }
}
