import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @StateObject var viewModel: AuthViewModel

    @State private var email = ""
    @State private var password = ""

    var body: some View {
        ScrollView {
            VStack {
                HeaderView()

                VStack(spacing: 12) {
                    CustomTextField(
                        text: $email,
                        icon: "envelope.fill",
                        placeholder: "Email",
                        keyboardType: .emailAddress
                    )

                    CustomTextField(
                        text: $password,
                        icon: "lock.fill",
                        placeholder: "Пароль",
                        isSecure: true
                    )
                }
                .padding(.vertical, 20)
                .cornerRadius(16)
                .padding(.horizontal, 20)

                PrimaryButton(title: "Войти") {
                }
                .padding(.horizontal, 16)

                VStack(spacing: 16) {


                    LegalTextSection()

                    DividerSection()
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
                            viewModel.login()
                        }

                        
                    }
                }
                .padding(.horizontal, 20)

            }
        }
    }
}



