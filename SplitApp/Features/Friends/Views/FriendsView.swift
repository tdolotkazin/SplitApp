import SwiftUI

struct FriendsView: View {
    @StateObject private var viewModel: FriendsViewModel

    init(friendsRepository: any FriendsRepository) {
        _viewModel = StateObject(
            wrappedValue: FriendsViewModel(friendsRepository: friendsRepository)
        )
    }

    var body: some View {
        ZStack {
            background
            content
        }
        .navigationBarHidden(true)
        .task {
            await viewModel.load()
        }
    }
}

private extension FriendsView {
    var background: some View {
        ZStack {
            AppTheme.backgroundGradient
                .ignoresSafeArea()

            AppTheme.backgroundRadialGlow
                .ignoresSafeArea()
        }
        .dismissKeyboardOnTap()
    }

    var content: some View {
        VStack(spacing: 0) {
            header
            searchBar
            scrollContent
        }
    }

    var header: some View {
        FriendsNavigationHeader()
            .onTapGesture {
                hideKeyboard()
            }
    }

    var searchBar: some View {
        SearchBar(searchText: $viewModel.searchText)
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 8)
    }

    var scrollContent: some View {
        ScrollView {
            VStack(spacing: 24) {
                activeDebtsSection
                allFriendsSection
                loadingState
                errorState
                emptyState
                bottomSpacer
            }
            .padding(.bottom, 32)
        }
        .refreshable {
            await viewModel.reload()
        }
        .scrollDismissesKeyboard(.interactively)
        .simultaneousGesture(
            TapGesture()
                .onEnded { _ in
                    hideKeyboard()
                }
        )
    }

    @ViewBuilder
    var activeDebtsSection: some View {
        if !viewModel.activeDebts.isEmpty {
            ActiveDebtsSection(
                debts: viewModel.activeDebts,
                onSettle: { debt in
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
                        viewModel.settleDebt(debt)
                    }
                }
            )
            .padding(.top, 8)
        }
    }

    @ViewBuilder
    var allFriendsSection: some View {
        if !viewModel.filteredFriends.isEmpty {
            AllFriendsSection(
                friends: viewModel.filteredFriends,
                startIndex: viewModel.activeDebts.count
            )
        }
    }

    @ViewBuilder
    var loadingState: some View {
        if viewModel.isLoading {
            ProgressView("Загружаем друзей...")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.textSecondary)
                .padding(.top, 16)
        }
    }

    @ViewBuilder
    var errorState: some View {
        if !viewModel.isLoading,
           viewModel.filteredFriends.isEmpty,
           let errorMessage = viewModel.errorMessage
        {
            Text(errorMessage)
                .font(.system(size: 15, weight: .regular, design: .rounded))
                .foregroundStyle(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
                .padding(.top, 24)
        }
    }

    @ViewBuilder
    var emptyState: some View {
        if viewModel.filteredFriends.isEmpty, !viewModel.searchText.isEmpty {
            EmptySearchState()
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
        }
    }

    var bottomSpacer: some View {
        Color.clear
            .frame(minHeight: 100)
            .contentShape(Rectangle())
    }
}

#Preview {
    NavigationStack {
        FriendsView(
            friendsRepository: FriendsDataRepository(
                usersRepository: UsersDataRepository()
            )
        )
    }
}
