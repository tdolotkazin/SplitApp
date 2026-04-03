import SwiftUI

struct TabPlaceholderView: View {
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "hammer")
                .font(.system(size: 30))
                .foregroundStyle(.secondary)
            Text("Раздел пока не готов")
                .font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .navigationTitle(title)
    }
}

#Preview {
    NavigationStack {
        TabPlaceholderView(
            title: "Плейсхолдер",
            message: "Замените этот экран на фичу команды."
        )
    }
}
