import SwiftUI

struct LegalTextSection: View {
    var body: some View {
        VStack(spacing: 8) {
            Text("Регистрируясь, вы соглашаетесь с")
                .font(.caption)
                .foregroundColor(.secondary)

            HStack(spacing: 4) {
                Link(
                    "условиями использования",
                    destination: URL(string: "https://example.com/terms")!
                )
                .font(.caption)
                .foregroundColor(.blue)

                Text("и")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Link(
                    "политикой конфиденциальности",
                    destination: URL(string: "https://example.com/privacy")!
                )
                .font(.caption)
                .foregroundColor(.blue)
            }
        }
        .multilineTextAlignment(.center)
    }
}

struct DividerSection: View {
    var body: some View {
        HStack {
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 1)

            Text("или войти через")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 1)

            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 1)
        }
    }
}

struct LoginPromptSection: View {
    var body: some View {
        HStack(spacing: 4) {
            Text("Уже есть аккаунт?")
                .font(.caption)
                .foregroundColor(.secondary)

            Button("Войти") {
                // Handle login navigation
            }
            .font(.caption)
            .foregroundColor(.blue)
        }
        .padding(.top, 8)
    }
}

struct LegalTextSection_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            LegalTextSection()
            DividerSection()
            LoginPromptSection()
        }
        .padding()
    }
}
