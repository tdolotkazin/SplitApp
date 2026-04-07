import SwiftUI

struct AllFriendsSection: View {
    let friends: [Friend]
    let startIndex: Int
    let onFriendTap: (Friend) -> Void


    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Все друзья")
                .padding(.horizontal, 20)

            VStack(spacing: 8) {
                ForEach(Array(friends.enumerated()), id: \.element.id) { index, friend in
                    Button(action: {
                        hideKeyboard()
                        onFriendTap(friend)
                    }) {
                        FriendRowView(friend: friend)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.horizontal, 20)
                    .staggeredAppear(index: startIndex + index)
                }
            }
        }
    }
}
