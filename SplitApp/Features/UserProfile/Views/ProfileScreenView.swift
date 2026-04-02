//import SwiftUI
//
//struct ProfileScreenView: View {
//   // let model: ProfileScreenModel
//    @State private var notificationsEnabled: Bool
//
//    init(
//       // model: ProfileScreenModel,
//        notificationsEnabled: Bool = true
//    ) {
//        self.model = model
//        _notificationsEnabled = State(initialValue: notificationsEnabled)
//    }
//
//    private var settingsItems: [ProfileSettingsItemModel] {
//        model.settings.map { item in
//            switch item.kind {
//            case .toggle:
//                return ProfileSettingsItemModel(
//                    icon: item.icon,
//                    iconColor: item.iconColor,
//                    iconBackgroundColor: item.iconBackgroundColor,
//                    title: item.title,
//                    titleColor: item.titleColor,
//                    kind: .toggle(isOn: notificationsEnabled)
//                )
//            default:
//                return item
//            }
//        }
//    }
//
//    var body: some View {
//        ZStack(alignment: .bottom) {
//            Color(.systemGray6)
//                .ignoresSafeArea()
//
//            ScrollView(showsIndicators: false) {
//                VStack(alignment: .leading, spacing: 20) {
//                    Text(model.title)
//                        .font(.largeTitle)
//                        .fontWeight(.bold)
//                        .padding(.top, 16)
//
//                    ProfileCardView(profileData: model.profile)
//
//                    ProfileStatsGridView()
//
//                    ProfileSettingsCardView(
//                        items: settingsItems,
//                        onToggleChanged: { newValue in
//                            notificationsEnabled = newValue
//                        }
//                    )
//                }
//                .padding(.horizontal, 20)
//                .padding(.bottom, 100)
//            }
//            BottomTabBarView()
//        }
//    }
//
//    private func tabItem(icon: String, title: String, selected: Bool) -> some View {
//        VStack(spacing: 4) {
//            Image(systemName: icon)
//                .font(.system(size: 22))
//
//            Text(title)
//                .font(.caption)
//        }
//        .foregroundColor(selected ? .indigo : .gray)
//    }
//}
//
////#Preview {
////    ProfileView(model: .mock, notificationsEnabled: true)
////}
////

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
        ZStack(alignment: .bottom) {
            Color(.systemGray6)
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    Text(model.title)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.top, 16)

                    ProfileCardView(
                        initials: model.initials,
                        name: model.name,
                        email: model.email
                    )

                    ProfileStatsGridView(
                        eventsCountText: model.eventsCountText,
                        friendsCountText: model.friendsCountText,
                        closedBillsText: model.closedBillsText,
                        openBillsText: model.openBillsText
                    )

                    ProfileSettingsCardView(
                        currencyText: model.currencyText,
                        notificationsEnabled: $notificationsEnabled
                    )
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 100)
            }

            BottomTabBarView()
        }
    }
}

//#Preview {
//    ProfileScreenView(model: .mock)
//}
