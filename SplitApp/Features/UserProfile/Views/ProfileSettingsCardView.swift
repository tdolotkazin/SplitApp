////import SwiftUI
////
////struct ProfileSettingsCardView: View {
////    let onToggleChanged: (Bool) -> Void
////
////
////    var body: some View {
////        VStack(spacing: 0) {
////            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
////                ProfileSettingsRowView(
////                    item: item,
////                    onToggleChanged: onToggleChanged
////                )
////
////                if index < items.count - 1 {
////                    Divider()
////                        .padding(.leading, 68)
////                }
////            }
////        }
////        .background(Color.white)
////        .clipShape(RoundedRectangle(cornerRadius: 24))
////    }
////}
//
//import SwiftUI
//
//struct ProfileSettingsCardView: View {
//    let currencyText: String
//    @Binding var notificationsEnabled: Bool
//
//    var body: some View {
//        VStack(spacing: 0) {
//            ProfileSettingsRowView(
//                icon: "clock",
//                title: "Валюта"
//            ) {_ in 
//                HStack(spacing: 6) {
//                    Text(currencyText)
//                        .foregroundColor(.gray)
//
//                    Image(systemName: "chevron.right")
//                        .foregroundColor(.gray)
//                }
//            }
//
//            Divider()
//                .padding(.leading, 68)
//
//            ProfileSettingsRowView(
//                icon: "bell",
//                title: "Уведомления"
//            ) {
//                Toggle("", isOn: $notificationsEnabled)
//                    .labelsHidden()
//                    .tint(.green)
//            }
//
//            Divider()
//                .padding(.leading, 68)
//
//            ProfileSettingsRowView(
//                icon: "rectangle.portrait.and.arrow.right",
//                title: "Выйти",
//                titleColor: .red,
//                iconColor: .red,
//                iconBackgroundColor: Color.red.opacity(0.12)
//            ) {
//                Image(systemName: "chevron.right")
//                    .foregroundColor(.gray)
//            }
//        }
//        .background(.white)
//        .clipShape(RoundedRectangle(cornerRadius: 24))
//    }
//}

import SwiftUI

struct ProfileSettingsCardView: View {
    let currencyText: String
    @Binding var notificationsEnabled: Bool

    var body: some View {
        VStack(spacing: 0) {
            ProfileSettingsRowView(
                icon: "clock",
                title: "Валюта",
                iconColor: .indigo,
                iconBackgroundColor: Color.indigo.opacity(0.12)
            ) {
                HStack(spacing: 6) {
                    Text(currencyText)
                        .foregroundColor(.gray)

                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                }
            }

            Divider()
                .padding(.leading, 68)

            ProfileSettingsRowView(
                icon: "bell",
                title: "Уведомления",
                iconColor: .teal,
                iconBackgroundColor: Color.teal.opacity(0.12)
            ) {
                Toggle("", isOn: $notificationsEnabled)
                    .labelsHidden()
                    .tint(.green)
            }

            Divider()
                .padding(.leading, 68)

            ProfileSettingsRowView(
                icon: "rectangle.portrait.and.arrow.right",
                title: "Выйти",
                titleColor: .red,
                iconColor: .red,
                iconBackgroundColor: Color.red.opacity(0.12)
            ) {
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }
        }
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }
}
