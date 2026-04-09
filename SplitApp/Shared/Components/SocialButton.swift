import SwiftUI

struct SocialButton: View {
    let icon: String
    let backgroundColor: Color
    let textColor: Color
    var hasBorder: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Group {
                if icon == "yandex" {
                    Image(icon)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 112, height: 112)
                        .clipShape(Circle())
                        .contentShape(Circle())
                        .shadow(color: .black.opacity(0.06), radius: 18, y: 8)
                } else {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(textColor)
                        .frame(width: 25, height: 50)
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
        .frame(width: icon == "yandex" ? 112 : nil, height: icon == "yandex" ? 112 : nil)
        .buttonStyle(.plain)
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
