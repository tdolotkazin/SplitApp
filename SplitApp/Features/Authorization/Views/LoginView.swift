import SwiftUI

struct LoginView: View {
    @EnvironmentObject var appState: AppState
    @ObservedObject var viewModel: AuthViewModel

    var body: some View {
        ZStack {
            Color("ColorGreen")
                .ignoresSafeArea()
            VStack(spacing: 0) {
                Spacer(minLength: 80)

                HeaderView()
                    .padding(.horizontal, 28)

                Spacer()

                SocialButton(
                    icon: "yandex",
                    backgroundColor: .white,
                    textColor: .black,
                    hasBorder: false
                ) {
                    Task {
                        let success = await viewModel.login()
                        if success {
                            appState.isLoggedIn = true
                        }
                    }
                }

                Spacer(minLength: 180)
            }
        }
    }
}
