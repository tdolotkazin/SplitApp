import SwiftUI

struct EmptySearchState: View {


    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.slash")
                .font(.system(size: 56, weight: .thin))
                .foregroundStyle(AppTheme.textTertiary.opacity(0.5))
                .padding(.bottom, 8)

            Text("Друзья не найдены")
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)

            Text("Попробуйте изменить поисковый запрос")
                .font(.system(size: 15, weight: .regular, design: .rounded))
                .foregroundStyle(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 80)
        .padding(.bottom, 40)
    }
}


#Preview {
    ZStack {
        AppTheme.backgroundGradient
            .ignoresSafeArea()

        EmptySearchState()
    }
}
