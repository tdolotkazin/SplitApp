import SwiftUI

struct BillItemRow: View {
    let item: BillItem
    let onAssign: () -> Void
    let onDelete: () -> Void
    let onUpdate: (String, Decimal) -> Void
    let onInsertAnimationCompleted: () -> Void

    @State private var name: String
    @State private var amount: Decimal
    @State private var isDeleting: Bool = false
    @State private var didAppear = false
    @FocusState private var isNameFocused: Bool

    init(
        item: BillItem,
        onAssign: @escaping () -> Void,
        onDelete: @escaping () -> Void,
        onUpdate: @escaping (String, Decimal) -> Void,
        onInsertAnimationCompleted: @escaping () -> Void = {}
    ) {
        self.item = item
        self.onAssign = onAssign
        self.onDelete = onDelete
        self.onUpdate = onUpdate
        self.onInsertAnimationCompleted = onInsertAnimationCompleted
        _name = State(initialValue: item.name)
        _amount = State(initialValue: item.amount)
    }

    var body: some View {
        GlassCard(padding: 12) {
            HStack(spacing: 12) {
                TextField("Введите название", text: $name)
                    .font(AppTheme.fontBody)
                    .foregroundStyle(AppTheme.textPrimary)
                    .focused($isNameFocused)
                    .onChange(of: name) { _, newValue in
                        onUpdate(newValue, amount)
                    }
                    .frame(maxWidth: .infinity)

                AmountField(amount: $amount)
                    .frame(width: BillEntryColumns.amountWidth)
                    .onChange(of: amount) { _, newValue in
                        onUpdate(name, newValue)
                    }

                Button(
                    action: {
                        UIApplication.shared.sendAction(
                            #selector(UIResponder.resignFirstResponder),
                            to: nil,
                            from: nil,
                            for: nil
                        )
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            onAssign()
                        }
                    },
                    label: {
                        if let participant = item.assignedTo {
                            ParticipantAvatar(participant: participant)
                                .frame(maxWidth: .infinity)
                        } else {
                            HStack(spacing: 4) {
                                Image(systemName: "person.circle.fill")
                                    .font(.system(size: 17))
                                Text("Кто?")
                                    .font(.system(size: 14, weight: .medium))
                            }
                            .foregroundStyle(AppTheme.textTertiary)
                            .frame(maxWidth: .infinity)
                        }
                    }
                )
                .frame(width: BillEntryColumns.participantWidth)
                .buttonStyle(PlainButtonStyle())
            }
        }
        .opacity(item.isEditing ? (didAppear ? 1 : 0) : 1)
        .onAppear {
            guard item.isEditing else {
                didAppear = true
                return
            }

            withAnimation(
                .spring(response: 0.45, dampingFraction: 0.8),
                completionCriteria: .logicallyComplete
            ) {
                didAppear = true
            } completion: {
                onInsertAnimationCompleted()
            }
        }
        .onChange(of: item.isEditing) { _, isEditing in
            if !isEditing {
                didAppear = true
            }
        }
        .deleteTransition(isDeleting: isDeleting)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()

                withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
                    isDeleting = true
                }

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
