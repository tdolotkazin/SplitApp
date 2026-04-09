import Combine
import Foundation

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published var profileModel: ProfileScreenModel?
    @Published var isLoading = false
    @Published var error: Error?

    private let usersRepository: UsersRepository
    private let logoutUseCase: LogoutUseCase

    init(usersRepository: UsersRepository, logoutUseCase: LogoutUseCase) {
        self.usersRepository = usersRepository
        self.logoutUseCase = logoutUseCase
    }

    func loadProfile() async {
        isLoading = true
        error = nil

        guard let currentUser = await CurrentUserStore.shared.user else {
            handleMissingUser()
            return
        }

        print("✅ ProfileViewModel: CurrentUser found - \(currentUser.name)")

        do {
            try await loadProfileData(for: currentUser)
        } catch {
            handleLoadError(error, for: currentUser)
        }
    }

    private func handleMissingUser() {
        print("⚠️ ProfileViewModel: CurrentUser is nil, cannot load profile")
        profileModel = createPlaceholderModel()
        isLoading = false
    }

    private func loadProfileData(for currentUser: CurrentUser) async throws {
        print("📡 ProfileViewModel: Loading users list...")
        let users = try await usersRepository.listUsers()
        print("✅ ProfileViewModel: Loaded \(users.count) users")

        if let foundUser = users.first(where: { $0.id == currentUser.id }) {
            print("✅ ProfileViewModel: Found current user in list, updating...")
            await MainActor.run {
                CurrentUserStore.shared.updateFromAuth(foundUser)
            }
        } else {
            print("⚠️ ProfileViewModel: Current user NOT found in users list")
        }

        profileModel = createProfileModel(from: currentUser, friendsCount: users.count - 1)
        print("✅ ProfileViewModel: Profile model created successfully")
        isLoading = false
    }

    private func handleLoadError(_ error: Error, for currentUser: CurrentUser) {
        print("❌ ProfileViewModel: Error loading users - \(error)")
        profileModel = createProfileModel(from: currentUser, friendsCount: nil)
        self.error = error
        isLoading = false
    }

    private func createPlaceholderModel() -> ProfileScreenModel {
        ProfileScreenModel(
            initials: "?",
            email: "Не указан",
            name: "Загрузка...",
            eventsCountText: "—",
            friendsCountText: "—",
            closedBillsText: "—",
            openBillsText: "—",
            avatarURL: nil
        )
    }

    private func createProfileModel(from user: CurrentUser, friendsCount: Int?) -> ProfileScreenModel {
        ProfileScreenModel(
            initials: user.initials,
            email: user.email ?? "Не указан",
            name: user.name,
            eventsCountText: "—",
            friendsCountText: friendsCount.map(String.init) ?? "—",
            closedBillsText: "—",
            openBillsText: "—",
            avatarURL: user.avatarURL
        )
    }

    func logout() {
        logoutUseCase.execute()
        CurrentUserStore.shared.clear()
    }
}
