import SwiftUI

struct FriendsNavigationHeader: View {
    var body: some View {
        HStack(alignment: .center) {
            Text("Друзья")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }
}
