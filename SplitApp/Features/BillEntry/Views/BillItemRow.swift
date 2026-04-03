
import SwiftUI

struct BillItemRow: View {
    let item: BillItem
    let onAssign: () -> Void
    let onDelete: () -> Void
    let onUpdate: (String, Decimal) -> Void

    @State private var name: String
    @State private var amount: Decimal
    @State private var isDeleting: Bool = false
    @FocusState private var isNameFocused: Bool

    init(item: BillItem, onAssign: @escaping () -> Void, onDelete: @escaping () -> Void, onUpdate: @escaping (String, Decimal) -> Void) {
        self.item = item
        self.onAssign = onAssign
        self.onDelete = onDelete
        self.onUpdate = onUpdate
        _name = State(initialValue: item.name)
        _amount = State(initialValue: item.amount)
    }

    var body: some View {
        GlassCard(padding: 12) {
            HStack(spacing: 12) {
                // Название позиции
                TextField("Введите название", text: $name)
                    .font(AppTheme.fontBody)
                    .foregroundStyle(AppTheme.textPrimary)
                    .focused($isNameFocused)
                    .onChange(of: name) { oldValue, newValue in
                        onUpdate(newValue, amount)
                    }
                    .frame(maxWidth: .infinity)

                // Сумма
                AmountField(amount: $amount)
                    .frame(width: 80)
                    .onChange(of: amount) { oldValue, newValue in
                        onUpdate(name, newValue)
                    }

                // Кто платит
                Button(action: {
                    // Закрыть клавиатуру перед открытием sheet
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    // Небольшая задержка для плавности
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        onAssign()
                    }
                }) {
                    if let participant = item.assignedTo {
                        ParticipantAvatar(participant: participant)
                    } else {
                        HStack(spacing: 4) {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 16))
                            Text("Кто?")
                                .font(.system(size: 13, weight: .medium))
                        }
                        .foregroundStyle(AppTheme.textTertiary)
                        .frame(width: 70)
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .deleteTransition(isDeleting: isDeleting)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                // Haptic feedback
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()

                withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
                    isDeleting = true
                }

                // Задержка перед вызовом onDelete для завершения анимации
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    onDelete()
                }
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 20, weight: .semibold))
                    Text("Удалить")
                        .font(.system(size: 12, weight: .medium))
                }
            }
            .tint(.red)
        }
    }
}
