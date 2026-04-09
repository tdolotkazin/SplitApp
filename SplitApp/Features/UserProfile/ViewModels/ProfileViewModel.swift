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

        // Проверяем, что есть текущий пользователь
        guard let currentUser = CurrentUserStore.shared.user else {
            print("⚠️ ProfileViewModel: CurrentUser is nil, cannot load profile")
            // Создаем пустую модель с плейсхолдерами
            profileModel = ProfileScreenModel(
                initials: "?",
                email: "Не указан",
                name: "Загрузка...",
                eventsCountText: "—",
                friendsCountText: "—",
                closedBillsText: "—",
                openBillsText: "—",
                avatarURL: nil
            )
            isLoading = false
            return
        }

        print("✅ ProfileViewModel: CurrentUser found - \(currentUser.name)")

        do {
            // Загружаем список всех пользователей
            print("📡 ProfileViewModel: Loading users list...")
            let users = try await usersRepository.listUsers()
            print("✅ ProfileViewModel: Loaded \(users.count) users")

            // Находим текущего пользователя в списке
            if let foundUser = users.first(where: { $0.id == currentUser.id }) {
                print("✅ ProfileViewModel: Found current user in list, updating...")
                // Обновляем данные в CurrentUserStore если они изменились
                await MainActor.run {
                    CurrentUserStore.shared.updateFromAuth(foundUser)
                }
            } else {
                print("⚠️ ProfileViewModel: Current user NOT found in users list")
            }

            // Создаем модель профиля из данных CurrentUser
            profileModel = ProfileScreenModel(
                initials: currentUser.initials,
                email: currentUser.email ?? "Не указан",
                name: currentUser.name,
                eventsCountText: "—", // TODO: вычислять из событий
                friendsCountText: String(users.count - 1), // все пользователи кроме текущего
                closedBillsText: "—", // TODO: вычислять из счетов
                openBillsText: "—", // TODO: вычислять из счетов
                avatarURL: currentUser.avatarURL
            )
            print("✅ ProfileViewModel: Profile model created successfully")
            isLoading = false
        } catch {
            print("❌ ProfileViewModel: Error loading users - \(error)")
            // При ошибке показываем данные из кеша
            profileModel = ProfileScreenModel(
                initials: currentUser.initials,
                email: currentUser.email ?? "Не указан",
                name: currentUser.name,
                eventsCountText: "—",
                friendsCountText: "—",
                closedBillsText: "—",
                openBillsText: "—",
                avatarURL: currentUser.avatarURL
            )
            self.error = error
            isLoading = false
        }
    }

    func logout() {
        logoutUseCase.execute()
        CurrentUserStore.shared.clear()
    }
}
