import SwiftUI

struct AddFriendSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var friendName: String = ""
    let onAdd: (String) -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundGradient
                    .ignoresSafeArea()

                VStack(spacing: 24) {
                    Spacer()
                        .frame(height: 20)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Имя друга")
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundStyle(AppTheme.textSecondary)

                        TextField("Введите имя", text: $friendName)
                            .font(.system(size: 17, weight: .medium, design: .rounded))
                            .foregroundStyle(AppTheme.textPrimary)
                            .padding(16)
                            .background(AppTheme.cardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(AppTheme.cardBorder, lineWidth: 1)
                            )
                    }
                    .padding(.horizontal, 20)

                    Spacer()

                    Button(
                        action: {
                            guard !friendName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                            onAdd(friendName.trimmingCharacters(in: .whitespacesAndNewlines))
                            dismiss()
                        },
                        label: {
                            Text("Добавить")
                                .font(.system(size: 17, weight: .semibold, design: .rounded))
                                .foregroundStyle(AppTheme.accentForeground)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(AppTheme.accentGradient)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                    )
                    .disabled(friendName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .opacity(friendName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("Добавить друга")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") {
                        dismiss()
                    }
                    .foregroundStyle(AppTheme.textSecondary)
                }
            }
        }
    }
}

#Preview {
    AddFriendSheet(onAdd: { name in
        print("Added: \(name)")
    })
}
