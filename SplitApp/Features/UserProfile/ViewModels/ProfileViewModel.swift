import Combine
import Foundation

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published var profileModel: ProfileScreenModel?
    @Published var isLoading = false
    @Published var error: Error?

    private let usersRepository: UsersRepository
    private let eventsRepository: any EventsRepository
    private let logoutUseCase: LogoutUseCase

    init(usersRepository: any UsersRepository, eventsRepository: any EventsRepository, logoutUseCase: LogoutUseCase) {
        self.usersRepository = usersRepository
        self.eventsRepository = eventsRepository
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
        async let usersFetch = usersRepository.listUsers()
        async let eventsFetch = eventsRepository.listEvents(userId: nil)

        let users = try await usersFetch
        let events = try await eventsFetch
        print("✅ ProfileViewModel: Loaded \(users.count) users, \(events.count) events")

        if let foundUser = users.first(where: { $0.id == currentUser.id }) {
            print("✅ ProfileViewModel: Found current user in list, updating...")
            await MainActor.run {
                CurrentUserStore.shared.updateFromAuth(foundUser)
            }
        } else {
            print("⚠️ ProfileViewModel: Current user NOT found in users list")
        }

        profileModel = createProfileModel(from: currentUser, friendsCount: users.count - 1, eventsCount: events.count)
        print("✅ ProfileViewModel: Profile model created successfully")
        isLoading = false
    }

    private func handleLoadError(_ error: Error, for currentUser: CurrentUser) {
        print("❌ ProfileViewModel: Error loading users - \(error)")
        profileModel = createProfileModel(from: currentUser, friendsCount: nil, eventsCount: nil)
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
            avatarURL: nil
        )
    }

    private func createProfileModel(
        from user: CurrentUser, friendsCount: Int?, eventsCount: Int?
    ) -> ProfileScreenModel {
        ProfileScreenModel(
            initials: user.initials,
            email: user.email ?? "Не указан",
            name: user.name,
            eventsCountText: eventsCount.map(String.init) ?? "—",
            friendsCountText: friendsCount.map(String.init) ?? "—",
            avatarURL: user.avatarURL
        )
    }

    func logout() {
        logoutUseCase.execute()
        CurrentUserStore.shared.clear()
    }
}
