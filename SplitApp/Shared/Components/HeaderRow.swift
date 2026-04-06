import SwiftUI

struct HeaderRow: View {
    var body: some View {
        HStack(spacing: 12) {
            Text("ПОЗИЦИЯ")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .tracking(1.2)
                .foregroundStyle(AppTheme.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text("СУММА")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .tracking(1.2)
                .foregroundStyle(AppTheme.textSecondary)
                .frame(width: BillEntryColumns.amountWidth, alignment: .center)

            Text("КТО")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .tracking(1.2)
                .foregroundStyle(AppTheme.textSecondary)
                .frame(width: BillEntryColumns.participantWidth, alignment: .center)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}
