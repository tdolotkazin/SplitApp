import SwiftUI

struct ProfileStatCardView: View {
    let title: String
    let value: String
    let valueColor: Color

    var body: some View {
        GlassCard(padding: 20) {
            VStack(alignment: .leading, spacing: 16) {
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
                Text(value)
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(valueColor)
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, minHeight: 80, alignment: .topLeading)
        }
    }
}
