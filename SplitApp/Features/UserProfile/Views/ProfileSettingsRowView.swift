//import SwiftUI
//
//struct ProfileSettingsRowView: View {
//    let profileData: ProfileScreenModel
////    let color: Color
////    let title: String
////    let icon: String
//    let onToggleChanged: ((Bool) -> Void)?
//
//    var body: some View {
//        HStack(spacing: 14) {
//            settingsIcon
//            settingsText
//            Spacer()
//            trailingContent
//        }
//        .padding(.horizontal, 16)
//        .padding(.vertical, 18)
//    }
//
//    private var settingsIcon: some View {
//        ZStack {
//            RoundedRectangle(cornerRadius: 12)
//                .fill(color)
//                .frame(width: 40, height: 40)
//
//            Image(systemName: icon)
//                .foregroundColor(color)
//        }
//    }
//
//    private var settingsText: some View {
//        Text(title)
//                .font(.body)
//                .fontWeight(.medium)
//                .foregroundColor(.black)
//    }
//
//    @ViewBuilder
//    private var trailingContent: some View {
//        switch item.kind {
//        case .navigation(let value):
//            HStack(spacing: 6) {
//                Text(value)
//                    .foregroundColor(.gray)
//
//                Image(systemName: "chevron.right")
//                    .foregroundColor(.gray)
//            }
//
//        case .toggle(let isOn):
//            Toggle(
//                "",
//                isOn: Binding(
//                    get: { isOn },
//                    set: { newValue in
//                        onToggleChanged?(newValue)
//                    }
//                )
//            )
//            .labelsHidden()
//            .tint(.green)
//
//        case .action:
//            Image(systemName: "chevron.right")
//                .foregroundColor(.gray)
//        }
//    }
//}

import SwiftUI

struct ProfileSettingsRowView<Trailing: View>: View {
    let icon: String
    let title: String
    let titleColor: Color
    let iconColor: Color
    let iconBackgroundColor: Color
    let trailing: Trailing

    init(
        icon: String,
        title: String,
        titleColor: Color = .primary,
        iconColor: Color = .indigo,
        iconBackgroundColor: Color = Color.indigo.opacity(0.12),
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.icon = icon
        self.title = title
        self.titleColor = titleColor
        self.iconColor = iconColor
        self.iconBackgroundColor = iconBackgroundColor
        self.trailing = trailing()
    }

    var body: some View {
        HStack(spacing: 14) {
            settingsIcon
            settingsText
            Spacer()
            trailing
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 18)
    }

    private var settingsIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(iconBackgroundColor)
                .frame(width: 40, height: 40)

            Image(systemName: icon)
                .foregroundColor(iconColor)
        }
    }

    private var settingsText: some View {
        Text(title)
            .font(.body)
            .fontWeight(.medium)
            .foregroundColor(titleColor)
    }
}
