import SwiftUI

struct ProfileStatsGridView: View {
    let eventsCountText: String
    let friendsCountText: String
    let closedReceiptsText: String
    let openReceiptsText: String

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16),
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            events
            friends
            closedReceiptView
            openReceiptView
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

    private var closedReceiptView: some View {
        ProfileStatCardView(
            title: "Закрытые чеки",
            value: closedReceiptsText,
            valueColor: .green
        )
    }

    private var openReceiptView: some View {
        ProfileStatCardView(
            title: "Открытые чеки",
            value: openReceiptsText,
            valueColor: .red
        )
    }
}
