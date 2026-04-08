import SwiftUI

struct EventsHomeView: View {
    @ObservedObject var viewModel: EventsHomeViewModel

    let onScanTap: () -> Void
    let onAddTap: () -> Void
    let onBillTap: ((UUID) -> Void)?

    var body: some View {
        ZStack {
            ZStack {
                AppTheme.backgroundGradient
                    .ignoresSafeArea()

                AppTheme.backgroundRadialGlow
                    .ignoresSafeArea()
            }

            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        Text("События")
                            .font(.system(size: 38, weight: .semibold, design: .rounded))
                            .foregroundStyle(AppTheme.textPrimary)
                            .padding(.horizontal, 20)

                        BalanceCardView(summary: viewModel.balanceSummary)
                            .padding(.horizontal, 20)

                        if let currentEvent = viewModel.currentEvent {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("АКТУАЛЬНОЕ СОБЫТИЕ")
                                    .font(.system(size: 13, weight: .semibold))
                                    .tracking(1.2)
                                    .foregroundStyle(AppTheme.textSecondary)
                                    .padding(.horizontal, 20)

                        VStack(spacing: 0) {
                            ForEach(
                                Array(viewModel.latestEvents.enumerated()),
                                id: \.element.id
                            ) { index, event in
                                Button(action: { onEventTap(event.id) }, label: {
                                    EventRowView(event: event)
                                })

                                if index < viewModel.latestEvents.count - 1 {
                                    Divider()
                                        .padding(.leading, 52)
                                }
                            }
                        }
                    }
                    .padding(.top, 12)
                    .padding(.bottom, 120)
                }

                HStack(spacing: 12) {
                    ScanButton(action: onScanTap)

                    AddButton(action: onAddTap)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 8)
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.75), value: viewModel.currentEvent)
        .animation(.spring(response: 0.5, dampingFraction: 0.75), value: viewModel.currentEventBills.count)
        .navigationBarHidden(true)
    }
}

private struct BalanceCardView: View {
    let summary: EventBalanceSummary

    var body: some View {
        GlassCard(padding: 24) {
            VStack(alignment: .center, spacing: 8) {
                Text("Общий баланс")
                    .font(
                        .system(size: 18, weight: .semibold, design: .rounded)
                    )
                    .foregroundStyle(.white.opacity(0.8))
                Text(
                    summary.totalBalance.euroText(
                        signed: true,
                        minimumFractionDigits: 2
                    )
                )
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

private struct ScanButton: View {
    let action: () -> Void
    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            Text("Сканировать чек")
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(.ultraThinMaterial)
                .background(AppTheme.cardBackground)
                .foregroundStyle(AppTheme.accent)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLarge))
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLarge)
                        .stroke(AppTheme.cardBorder, lineWidth: 1)
                )
                .shadow(color: AppTheme.cardShadow, radius: 10, x: 0, y: 5)
                .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        isPressed = false
                    }
                }
        )
    }
}

private struct AddButton: View {
    let action: () -> Void
    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.system(size: 28, weight: .medium))
                .frame(width: 56, height: 56)
                .foregroundStyle(AppTheme.accentForeground)
                .background(AppTheme.accentGradient)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLarge))
                .shadow(color: AppTheme.accent.opacity(0.25), radius: 12, x: 0, y: 4)
                .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        isPressed = false
                    }
                }
        )
    }
}

#Preview {
    EventsHomeView(
        viewModel: EventsHomeViewModel(service: EventManagementService()),
        onScanTap: {},
        onAddTap: {},
        onEventTap: { _ in
        }
    )
}
