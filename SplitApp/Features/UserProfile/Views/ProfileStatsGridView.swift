import SwiftUI

struct ProfileStatsGridView: View {
    let eventsCountText: String
    let friendsCountText: String

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            events
            friends
        }
    }

    private var events: some View {
        ProfileStatCardView(
            title: "События",
            value: eventsCountText,
            valueColor: AppTheme.textPrimary
        )
    }

    private var friends: some View {
        ProfileStatCardView(
            title: "Друзья",
            value: friendsCountText,
            valueColor: AppTheme.textPrimary
        )
    }
}

