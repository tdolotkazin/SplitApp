import AuthenticationServices
import SwiftUI

struct LoginView: View {
    @EnvironmentObject var appState: AppState
    @StateObject var viewModel: AuthViewModel

    @State private var email = ""
    @State private var password = ""

    var body: some View {
        ScrollView {
            VStack {
                HeaderView()


                .padding(.vertical, 20)
                .cornerRadius(16)
                .padding(.horizontal, 20)

                PrimaryButton(title: "Войти") {
                }
                .padding(.horizontal, 16)

                VStack(spacing: 16) {

                    
                    HStack(spacing: 12) {
                        SocialButton(
                            icon: "applelogo",
                            backgroundColor: .black,
                            textColor: .white
                        ) {

                        }

                        SocialButton(

                            icon: "g.circle.fill",
                            backgroundColor: .white,
                            textColor: .black,
                            hasBorder: true
                        ) {

                        }

                        SocialButton(
                            icon: "g.circle.fill",
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
