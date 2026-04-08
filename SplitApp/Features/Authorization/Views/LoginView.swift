import SwiftUI

struct LoginView: View {
    @EnvironmentObject var appState: AppState
    @ObservedObject var viewModel: AuthViewModel

    var body: some View {
        ZStack {
            AppTheme.backgroundRadialGlow
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    HeaderView()
                        .padding(.horizontal, 16)

                    VStack(spacing: 16) {
                        LegalTextSection()

                        SocialButton(
                            icon: "yandex",
                            backgroundColor: .white,
                            textColor: .black,
                            hasBorder: true
                        ) {
                            Task {
                                let success = await viewModel.login()
                                if success {
                                    appState.isLoggedIn = true
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.vertical, 32)
            }
        }
    }
}
