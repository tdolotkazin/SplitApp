import SwiftUI

struct EventsHomeView: View {
    @ObservedObject var viewModel: EventsHomeViewModel

    let onScanTap: () -> Void
    let onAddTap: () -> Void

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        Text("События")
                            .font(.system(size: 38, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color(.label))

                        BalanceCardView(summary: viewModel.balanceSummary)

                        Text("ПОСЛЕДНИЕ СОБЫТИЯ")
                            .font(.system(size: 17, weight: .semibold))
                            .tracking(1.0)
                            .foregroundStyle(Color(.secondaryLabel))

                        VStack(spacing: 0) {
                            ForEach(Array(viewModel.latestEvents.enumerated()), id: \.element.id) { index, event in
                                EventRowView(event: event)

                                if index < viewModel.latestEvents.count - 1 {
                                    Divider()
                                        .padding(.leading, 52)
                                }
                            }
                        }
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 12)
                }

                HStack(spacing: 12) {
                    Button(action: onScanTap) {
                        Text("Сканировать чек")
                            .font(.system(size: 24, weight: .semibold, design: .rounded))
                            .minimumScaleFactor(0.3)
                            .lineLimit(1)
                            .frame(maxWidth: .infinity)
                            .frame(height: 76)
                            .background(Color(.systemBackground))
                            .foregroundStyle(Color.accentColor)
                            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    }

                    Button(action: onAddTap) {
                        Image(systemName: "plus")
                            .font(.system(size: 36, weight: .light))
                            .frame(width: 90, height: 90)
                            .background(Color.accentColor)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 12)
                .padding(.bottom, 18)
            }
        }
        .navigationBarHidden(true)
    }
}

private struct BalanceCardView: View {
    let summary: EventBalanceSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Общий баланс")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.8))
                Text(summary.totalBalance.euroText(signed: true, minimumFractionDigits: 2))
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
            }

            HStack(spacing: 12) {
                BalanceMiniTile(
                    title: "Вам должны",
                    amount: summary.owedToYou.euroText(minimumFractionDigits: 2)
                )
                BalanceMiniTile(
                    title: "Вы должны",
                    amount: summary.youOwe.euroText(minimumFractionDigits: 2)
                )
            }
        }
        .padding(18)
        .background(Color.accentColor)
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
    }
}

private struct BalanceMiniTile: View {
    let title: String
    let amount: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.62))
            Text(amount)
                .font(.system(size: 33, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(.white.opacity(0.13))
        .clipShape(RoundedRectangle(cornerRadius: 17, style: .continuous))
    }
}

#Preview {
    EventsHomeView(
        viewModel: .mock(),
        onScanTap: {},
        onAddTap: {}
    )
}
