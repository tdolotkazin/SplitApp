import SwiftUI

enum BottomTabID: String, Hashable {
    case events
    case friends
    case profile
}

struct BottomTabItem: Identifiable {
    let id: BottomTabID
    let title: String
    let systemImage: String
    let makeView: () -> AnyView

    init<Content: View>(
        id: BottomTabID,
        title: String,
        systemImage: String,
        @ViewBuilder makeView: @escaping () -> Content
    ) {
        self.id = id
        self.title = title
        self.systemImage = systemImage
        self.makeView = { AnyView(makeView()) }
    }
}

struct BottomTabConfiguration {
    let items: [BottomTabItem]
    let initialTab: BottomTabID

    init(
        items: [BottomTabItem],
        initialTab: BottomTabID = .events
    ) {
        self.items = items
        self.initialTab = initialTab
    }
}

extension BottomTabConfiguration {
    static func `default`(appState: AppState) -> BottomTabConfiguration {
        // создаём хранилище токенов
        let storage = KeychainStorage()

        // создаём useCase для выхода (удаляет токены и обновляет appState)
        let logoutUseCase = LogoutUseCase(secureStorage: storage, appState: appState)

        // создаём ViewModel для профиля
        let profileVM = ProfileViewModel(logoutUseCase: logoutUseCase)

        return BottomTabConfiguration(
            items: [
                BottomTabItem(
                    id: .events,
                    title: "События",
                    systemImage: "square.grid.2x2"
                ) {
                    EventsNavigationView()
                },
                BottomTabItem(
                    id: .friends,
                    title: "Друзья",
                    systemImage: "person.2"
                ) {
                    NavigationStack {
                        TabPlaceholderView(
                            title: "Друзья",
                            message: "Экран в разработке. Пока можно пользоваться только экраном событий."
                        )
                    }
                },
                BottomTabItem(
                    id: .profile,
                    title: "Профиль",
                    systemImage: "person.crop.circle"
                ) {
                    ProfileScreenView(
                        model: ProfileScreenModel(
                            initials: "ИВ",
                            email: "ivan@example.com",
                            name: "Иван Волков 🌸",
                            eventsCountText: "12",
                            friendsCountText: "8",
                            closedBillsText: "€340",
                            openBillsText: "€34"
                        ),
                        viewModel: profileVM
                    )
                }
            ]
        )
    }
}
