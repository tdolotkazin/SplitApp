import SwiftUI

struct ActiveDebtsSection: View {
    let debts: [FriendDebt]
    let onSettle: (FriendDebt) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Активные долги")
                .padding(.horizontal, 20)

            VStack(spacing: 12) {
                ForEach(Array(debts.enumerated()), id: \.element.id) { index, debt in
                    FriendDebtCard(debt: debt) {
                        onSettle(debt)
                    }
                    .padding(.horizontal, 20)
                    .staggeredAppear(index: index)
                }
            }
        }
    }
}
