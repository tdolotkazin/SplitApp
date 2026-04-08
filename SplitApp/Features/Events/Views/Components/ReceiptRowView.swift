import SwiftUI

struct ReceiptRowView: View {
    let receipt: Receipt
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.accentColor.opacity(0.1))
                        .frame(width: 44, height: 44)

                    Image(systemName: "receipt")
                        .font(.system(size: 20))
                        .foregroundStyle(Color.accentColor)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(receipt.title ?? "Чек")
                        .font(
                            .system(
                                size: 17,
                                weight: .semibold,
                                design: .rounded
                            )
                        )
                        .foregroundStyle(Color(.label))

                    Text(formatDate(receipt.createdAt))
                        .font(
                            .system(size: 14, weight: .medium, design: .rounded)
                        )
                        .foregroundStyle(Color(.secondaryLabel))
                }

                Spacer()

                Text(receipt.totalAmount.euroText(minimumFractionDigits: 2))
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.accentColor)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter.string(from: date)
    }
}
