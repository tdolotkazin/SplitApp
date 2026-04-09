import SwiftUI

struct SocialButton: View {
    let icon: String
    let backgroundColor: Color
    let textColor: Color
    var hasBorder: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                if icon == "yandex" {
                    Image(icon)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 32, height: 32)
                } else {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(textColor)
                }
            }
            .frame(width: 25)
            .frame(height: 50)
            .padding(.horizontal, 20)
            .background(backgroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: 25)
                    .stroke(
                        hasBorder ? Color.gray.opacity(0.3) : Color.clear,
                        lineWidth: 1
                    )
            )
            .cornerRadius(25)
        }
    }
}

struct SocialButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 16) {
            SocialButton(
                icon: "applelogo",
                backgroundColor: .black,
                textColor: .white
            ) {
                print("Apple sign in")
            }

            SocialButton(
                icon: "yandex",
                backgroundColor: .white,
                textColor: .black,
                hasBorder: true
            ) {
                print("Yandex sign in")
            }
        }
        .padding()
    }
}
