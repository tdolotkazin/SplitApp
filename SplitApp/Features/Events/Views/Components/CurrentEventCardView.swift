import SwiftUI

struct CurrentEventCardView: View {
    let event: EventListItem

    var body: some View {
        GlassCard(padding: 14) {
            HStack(spacing: 12) {
                Text(event.emoji)
                    .font(.system(size: 28))

                Text(event.title)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)

                Spacer()

                Text(formattedAmount)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(amountColor)
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                .stroke(AppTheme.accent, lineWidth: 2)
        )
    }

    private var formattedAmount: String {
        event.amount.euroText(signed: true, minimumFractionDigits: 0)
    }

    private var amountColor: Color {
        switch event.tone {
        case .positive:
            return Color(red: 0.17, green: 0.76, blue: 0.32)
        case .negative:
            return Color(red: 0.92, green: 0.29, blue: 0.29)
        case .neutral:
            return AppTheme.textSecondary
        }
    }
}
