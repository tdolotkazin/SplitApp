//import SwiftUI
//
//struct EventsListView: View {
//    var body: some View {
//        ZStack {
//            Color(.systemGray6)
//                .ignoresSafeArea()
//
//            VStack(spacing: 0) {
//                ScrollView(showsIndicators: false) {
//                    LazyVStack(alignment: .leading, spacing: 0) {
//                        Text("Актуальное событие")
//                            .font(.system(size: 22, weight: .bold))
//                            .foregroundColor(.black)
//                            .padding(.top, 28)
//
//                        ActiveEventCardView(
//                            emoji: "🍕",
//                            title: "Пицца-пятница",
//                            subtitle: "4 уч. · вчера",
//                            amount: "+€12"
//                        )
//                        .padding(.top, 20)
//
//                        HStack(spacing: 8) {
//                            Text("Выбрать событие")
//                                .font(.system(size: 20, weight: .semibold))
//                                .foregroundColor(Color.gray)
//
//                            Spacer()
//
//                            Button(action: {}) {
//                                Image(systemName: "plus")
//                                    .font(.system(size: 24, weight: .bold))
//                                    .foregroundColor(Color(red: 0.36, green: 0.37, blue: 0.92))
//                            }
//                        }
//                        .padding(.top, 40)
//
//                        VStack(spacing: 12) {
//                            EventGroupCardView()
//
//                            EventGroupCardView()
//                        }
//                        .padding(.top, 16)
//
//                        Spacer(minLength: 24)
//                    }
//                    .padding(.horizontal, 24)
//                }
//            }
//        }
//    }
//}
//
//struct ActiveEventCardView: View {
//    let emoji: String
//    let title: String
//    let subtitle: String
//    let amount: String
//
//    var body: some View {
//        HStack(spacing: 14) {
//            Text(emoji)
//                .font(.system(size: 28))
//
//            VStack(alignment: .leading, spacing: 4) {
//                Text(title)
//                    .font(.system(size: 17, weight: .bold))
//                    .foregroundColor(.black)
//
//                Text(subtitle)
//                    .font(.system(size: 14, weight: .medium))
//                    .foregroundColor(.gray)
//            }
//
//            Spacer()
//
//            Text(amount)
//                .font(.system(size: 17, weight: .bold))
//                .foregroundColor(.green)
//        }
//        .padding(.horizontal, 18)
//        .padding(.vertical, 18)
//        .background(
//            RoundedRectangle(cornerRadius: 24, style: .continuous)
//                .fill(Color.white)
//        )
//        .overlay(
//            RoundedRectangle(cornerRadius: 24, style: .continuous)
//                .stroke(Color(red: 0.36, green: 0.37, blue: 0.92), lineWidth: 3)
//        )
//    }
//}
//
//struct EventGroupCardView: View {
//    var body: some View {
//        VStack(spacing: 0) {
//            EventRowView(
//                event: )
//
//            Divider()
//                .padding(.leading, 56)
//
//            EventRowView(
//                emoji: "🏖",
//                title: "Амстердам",
//                subtitle: "6 уч. · 2 нед.",
//                trailingText: "Закрыт",
//                trailingColor: .gray
//            )
//        }
//        .background(
//            RoundedRectangle(cornerRadius: 22, style: .continuous)
//                .fill(Color.white)
//        )
//    }
//}
//
//#Preview {
//    EventsListView()
//}
