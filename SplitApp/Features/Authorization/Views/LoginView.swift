import AuthenticationServices
import SwiftUI

struct LoginView: View {
    @EnvironmentObject var appState: AppState
    @StateObject var viewModel: AuthViewModel

    var body: some View {
        ZStack {
            AppTheme.backgroundRadialGlow
                .ignoresSafeArea()

            VStack {
                HeaderView()
                    .padding(.horizontal, 16)
                VStack(spacing: 16) {

                    HStack(spacing: 12) {

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
                }
                .padding(.horizontal, 20)

            }
        }
    }
}
