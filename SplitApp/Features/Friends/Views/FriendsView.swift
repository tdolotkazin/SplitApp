import SwiftUI

struct FriendsView: View {
    @StateObject private var viewModel = FriendsViewModel()
    @State private var showAddFriend = false

    var body: some View {
        NavigationStack {
            ZStack {
                ZStack {
                    AppTheme.backgroundGradient
                        .ignoresSafeArea()

                    AppTheme.backgroundRadialGlow
                        .ignoresSafeArea()
                }
                .dismissKeyboardOnTap()

                ScrollView {
                    VStack(spacing: 20) {
                        SearchBar(searchText: $viewModel.searchText)
                            .padding(.horizontal, 20)
                            .padding(.top, 8)

                        if !viewModel.activeDebts.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("АКТИВНЫЕ ДОЛГИ")
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                                    .foregroundStyle(AppTheme.textTertiary)
                                    .padding(.horizontal, 20)

                                VStack(spacing: 12) {
                                    ForEach(Array(viewModel.activeDebts.enumerated()), id: \.element.id) { index, debt in
                                        FriendDebtCard(debt: debt) {
                                            withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
                                                viewModel.settleDebt(debt)
                                            }
                                        }
                                        .padding(.horizontal, 20)
                                        .staggeredAppear(index: index)
                                    }
                                }
                            }
                        }

                        if !viewModel.filteredFriends.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("ВСЕ ДРУЗЬЯ")
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                                    .foregroundStyle(AppTheme.textTertiary)
                                    .padding(.horizontal, 20)

                                VStack(spacing: 8) {
                                    ForEach(Array(viewModel.filteredFriends.enumerated()), id: \.element.id) { index, friend in
                                        Button(action: {
                                            // Обработка нажатия на друга
                                        }) {
                                            FriendRowView(friend: friend)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                        .padding(.horizontal, 20)
                                        .staggeredAppear(index: index + viewModel.activeDebts.count)
                                    }
                                }
                            }
                        }

                        if viewModel.filteredFriends.isEmpty && !viewModel.searchText.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "person.slash")
                                    .font(.system(size: 48, weight: .light))
                                    .foregroundStyle(AppTheme.textTertiary)

                                Text("Друзья не найдены")
                                    .font(.system(size: 17, weight: .medium, design: .rounded))
                                    .foregroundStyle(AppTheme.textSecondary)

                                Text("Попробуйте изменить поисковый запрос")
                                    .font(.system(size: 15, weight: .regular, design: .rounded))
                                    .foregroundStyle(AppTheme.textTertiary)
                            }
                            .padding(.top, 60)
                            .transition(.opacity)
                        }
                    }
                    .padding(.bottom, 20)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationTitle("Друзья")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showAddFriend = true
                    }) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(AppTheme.accentGradient)
                                .frame(width: 44, height: 44)

                            Image(systemName: "plus")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundStyle(AppTheme.accentForeground)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }
}

#Preview {
    FriendsView()
}
