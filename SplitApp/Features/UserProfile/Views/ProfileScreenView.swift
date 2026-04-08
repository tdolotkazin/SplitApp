import SwiftUI

struct ProfileScreenView: View {
    let model: ProfileScreenModel
    @State private var notificationsEnabled: Bool
    @ObservedObject var viewModel: ProfileViewModel

    init(
        model: ProfileScreenModel,
        viewModel: ProfileViewModel,
        notificationsEnabled: Bool = true
    ) {
        self.model = model
        self.viewModel = viewModel
        _notificationsEnabled = State(initialValue: notificationsEnabled)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color(.systemGray6)
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
            .font(.largeTitle)
            .fontWeight(.bold)
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
            notificationsEnabled: $notificationsEnabled, viewModel: viewModel)
    }
}
