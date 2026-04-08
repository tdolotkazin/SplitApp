import SwiftUI

struct CustomTextField: View {
    @Binding var text: String
    let icon: String
    let placeholder: String
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.gray)
                .frame(width: 20)
            
            if isSecure {
                SecureField(placeholder, text: $text)
                    .font(.body)
                    .textFieldStyle(PlainTextFieldStyle())
            } else {
                TextField(placeholder, text: $text)
                    .font(.body)
                    .keyboardType(keyboardType)
                    .textFieldStyle(PlainTextFieldStyle())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white)
        .cornerRadius(12)
        .border(Color.gray.opacity(0.3), width: 1)
    }
}

struct CustomTextField_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 16) {
            CustomTextField(
                text: .constant(""),
                icon: "person.fill",
                placeholder: "Имя и фамилия"
            )
            
            CustomTextField(
                text: .constant(""),
                icon: "envelope.fill",
                placeholder: "Email",
                keyboardType: .emailAddress
            )
            
            CustomTextField(
                text: .constant(""),
                icon: "lock.fill",
                placeholder: "Пароль",
                isSecure: true
            )
        }
        .padding()
    }
}
