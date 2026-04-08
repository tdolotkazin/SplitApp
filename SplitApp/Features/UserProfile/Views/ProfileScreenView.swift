import SwiftUI

struct ProfileScreenView: View {
    let model: ProfileScreenModel
    @State private var notificationsEnabled: Bool

    init(
        model: ProfileScreenModel,
        notificationsEnabled: Bool = true
    ) {
        self.model = model
        _notificationsEnabled = State(initialValue: notificationsEnabled)
    }

    var body: some View {
        ZStack {
            AppTheme.backgroundGradient
                .ignoresSafeArea()

            AppTheme.backgroundRadialGlow
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    profileText
                    userCard
                    userGrid
                    profileNotifications
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 100)
            }
        }
    }

    private var profileText: some View {
        Text("Профиль")
            .font(AppTheme.fontLargeTitle)
            .foregroundStyle(AppTheme.textPrimary)
            .padding(.top, 16)
    }

    private var userCard: some View {
        ProfileCardView(
            initials: model.initials,
            name: model.name,
            email: model.email
        )
    }

    private var userGrid: some View {
        ProfileStatsGridView(
            eventsCountText: model.eventsCountText,
            friendsCountText: model.friendsCountText,
            closedBillsText: model.closedBillsText,
            openBillsText: model.openBillsText
        )
    }

    private var profileNotifications: some View {
        ProfileSettingsCardView(
            notificationsEnabled: $notificationsEnabled
        )
    }
}
