import SwiftUI

struct ProfileStatsGridView: View {
    let eventsCountText: String
    let friendsCountText: String
    let closedBillsText: String
    let openBillsText: String

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            events
            friends
            closeBill
            openBill
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

    private var closeBill: some View {
        ProfileStatCardView(
            title: "Закрытые счета",
            value: closedBillsText,
            valueColor: AppTheme.accent
        )
    }

    private var openBill: some View {
        ProfileStatCardView(
            title: "Открытые счета",
            value: openBillsText,
            valueColor: .red
        )
    }
}
