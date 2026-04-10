import SwiftUI

struct BillRowView: View {
    let bill: BillListItem
    let onDelete: () -> Void
    let onTap: (() -> Void)?

    @State private var isDeleting: Bool = false
    @State private var showImageViewer = false

    init(bill: BillListItem, onDelete: @escaping () -> Void, onTap: (() -> Void)? = nil) {
        self.bill = bill
        self.onDelete = onDelete
        self.onTap = onTap
    }

    var body: some View {
        GlassCard(padding: 12) {
            HStack(spacing: 12) {
                receiptIcon

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
        .sheet(isPresented: $showImageViewer) {
            if let url = bill.imageURL {
                ReceiptImageViewerSheet(url: url, title: bill.title)
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

    @ViewBuilder
    private var receiptIcon: some View {
        if let url = bill.imageURL {
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                showImageViewer = true
            } label: {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 44, height: 44)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(AppTheme.accent.opacity(0.3), lineWidth: 1)
                            )
                    default:
                        Text(bill.emoji)
                            .font(.system(size: 28))
                            .frame(width: 44, height: 44)
                    }
                }
            }
            .buttonStyle(.plain)
        } else {
            Text(bill.emoji)
                .font(.system(size: 28))
                .frame(width: 44, height: 44)
        }
    }

    private var amountLabel: String {
        switch bill.tone {
        case .positive:
            bill.amount.rubleText(signed: true, minimumFractionDigits: 0)
        case .negative:
            bill.amount.rubleText(signed: true, minimumFractionDigits: 0)
        case .neutral:
            "Закрыт"
        }
    }
}
