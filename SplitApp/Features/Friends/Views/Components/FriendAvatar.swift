import SwiftUI

struct FriendAvatar: View {
    let friend: Friend
    var size: CGFloat = 56

    var body: some View {
        Group {
            if let avatarUrl = friend.avatarUrl, let url = URL(string: avatarUrl) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        placeholderView
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure:
                        placeholderView
                    @unknown default:
                        placeholderView
                    }
                }
            } else {
                placeholderView
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(
            Circle()
                .stroke(AppTheme.avatarStroke, lineWidth: 1)
        )
    }

    private var placeholderView: some View {
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
