import SwiftUI

struct CurrentEventCardView: View {
    let event: EventListItem

    var body: some View {
        GlassCard(padding: 14) {
            HStack(spacing: 12) {
                Text(event.emoji)
                    .font(.system(size: 28))

                VStack(alignment: .leading, spacing: 3) {
                    Text(event.title)
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundStyle(AppTheme.textPrimary)

                    Text(event.subtitle)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(AppTheme.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppTheme.textSecondary)
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                .stroke(AppTheme.accent, lineWidth: 2)
        )
    }
}
