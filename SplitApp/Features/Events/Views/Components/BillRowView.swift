import SwiftUI

struct BillRowView: View {
    let bill: BillListItem
    let onDelete: () -> Void
    let onTap: (() -> Void)?

    @State private var isDeleting: Bool = false

    init(bill: BillListItem, onDelete: @escaping () -> Void, onTap: (() -> Void)? = nil) {
        self.bill = bill
        self.onDelete = onDelete
        self.onTap = onTap
    }

    var body: some View {
        GlassCard(padding: 12) {
            HStack(spacing: 12) {
                Text(bill.emoji)
                    .font(.system(size: 28))
                    .frame(width: 44, height: 44)

                VStack(alignment: .leading, spacing: 3) {
                    Text(bill.title)
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(AppTheme.textPrimary)

                    Text(bill.subtitle)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(AppTheme.textSecondary)
                }

                Spacer()

                Text(amountLabel)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        bill.tone == .neutral
                            ? AnyShapeStyle(AppTheme.textSecondary)
                            : AnyShapeStyle(
                                AppTheme.accentGradient
                            )
                    )
            }
        }
        .onTapGesture {
            onTap?()
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

    private var amountLabel: String {
        switch bill.tone {
        case .positive:
            return bill.amount.euroText(signed: true, minimumFractionDigits: 0)
        case .negative:
            return bill.amount.euroText(signed: true, minimumFractionDigits: 0)
        case .neutral:
            return "Закрыт"
        }
    }
}
