import SwiftUI

struct AllFriendsSection: View {
    let friends: [Friend]
    let startIndex: Int
    let onFriendTap: (Friend) -> Void
    let onDelete: ((Friend) -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Все друзья")
                .padding(.horizontal, 20)

            List {
                ForEach(Array(friends.enumerated()), id: \.element.id) { index, friend in
                    Button(
                        action: {
                            hideKeyboard()
                            onFriendTap(friend)
                        },
                        label: {
                            FriendRowView(friend: friend)
                        }
                    )
                    .buttonStyle(PlainButtonStyle())
                    .listRowInsets(EdgeInsets(top: 4, leading: 20, bottom: 4, trailing: 20))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        if onDelete != nil {
                            Button(role: .destructive) {
                                onDelete?(friend)
                            } label: {
                                Label("Удалить", systemImage: "trash")
                            }
                            .tint(.red)
                        }
                    }
                    .staggeredAppear(index: startIndex + index)
                }
            }
            .listStyle(.plain)
            .scrollDisabled(true)
            .frame(height: CGFloat(friends.count) * 92)
            .animation(.easeInOut, value: friends.count)
        }
    }
}
