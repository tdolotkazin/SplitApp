import SwiftUI

struct ProfileScreenView: View {
    @State private var notificationsEnabled: Bool
    @ObservedObject var viewModel: ProfileViewModel

    init(
        viewModel: ProfileViewModel,
        notificationsEnabled: Bool = true
    ) {
        self.viewModel = viewModel
        _notificationsEnabled = State(initialValue: notificationsEnabled)
    }

    var body: some View {
        ZStack {
            ZStack {
                AppTheme.backgroundGradient
                    .ignoresSafeArea()
                AppTheme.backgroundRadialGlow
                    .ignoresSafeArea()
            }

            if viewModel.isLoading, viewModel.profileModel == nil {
                ProgressView()
                    .scaleEffect(1.5)
            } else if let model = viewModel.profileModel {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        profileTitle
                        userCard(model: model)
                        userGrid(model: model)
                        profileNotifications
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100)
                }
            } else {
                VStack(spacing: 16) {
                    Text("Не удалось загрузить профиль")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(AppTheme.textSecondary)
                    Button("Попробовать снова") {
                        Task {
                            await viewModel.loadProfile()
                        }
                    }
                }
            }
        }
        .task {
            await viewModel.loadProfile()
        }
    }

    private var profileTitle: some View {
        Text("Профиль")
            .font(AppTheme.fontLargeTitle)
            .foregroundStyle(AppTheme.textPrimary)
            .padding(.top, 16)
    }

    private func userCard(model: ProfileScreenModel) -> some View {
        ProfileCardView(
            initials: model.initials,
            name: model.name,
            email: model.email,
            avatarURL: model.avatarURL
        )
    }

    private func userGrid(model: ProfileScreenModel) -> some View {
        ProfileStatsGridView(
            eventsCountText: model.eventsCountText,
            friendsCountText: model.friendsCountText,
        )
    }

    private var profileNotifications: some View {
        ProfileSettingsCardView(
            notificationsEnabled: $notificationsEnabled,
            viewModel: viewModel
        )
    }
}
