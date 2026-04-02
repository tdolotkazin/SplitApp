import SwiftUI

struct BottomTabBarView: View {
    var body: some View {
        HStack {
            TabBarItemView(
                icon: "square.grid.2x2",
                title: "События",
                isSelected: false
            )

            Spacer()

            TabBarItemView(
                icon: "person.2",
                title: "Друзья",
                isSelected: false
            )

            Spacer()

            TabBarItemView(
                icon: "person.crop.circle",
                title: "Профиль",
                isSelected: true
            )
        }
        .padding(.horizontal, 32)
        .background(.ultraThinMaterial)
        .glassEffect(.regular)
    }
}

private struct TabBarItemView: View {
    let icon: String
    let title: String
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 22))

            Text(title)
                .font(.caption)
        }
        .foregroundColor(isSelected ? .indigo : .gray)
    }
}

#Preview {
    BottomTabBarView()
}
