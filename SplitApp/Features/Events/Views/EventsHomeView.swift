import SwiftUI

struct EventsHomeView: View {
    @ObservedObject var viewModel: EventsHomeViewModel

    let onScanTap: () -> Void
    let onAddTap: () -> Void
    let onBillTap: ((UUID) -> Void)?
    let onEventTap: (UUID) -> Void

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

                        VStack(alignment: .leading, spacing: 12) {
                            Text("АКТУАЛЬНОЕ СОБЫТИЕ")
                                .font(.system(size: 13, weight: .semibold))
                                .tracking(1.2)
                                .foregroundStyle(AppTheme.textSecondary)
                                .padding(.horizontal, 20)

                            if let currentEvent = viewModel.currentEvent {
                                Button(
                                    action: { onEventTap?() },
                                    label: { CurrentEventCardView(event: currentEvent) }
                                )
                                .buttonStyle(PlainButtonStyle())
                                .padding(.horizontal, 20)
                                .transition(.move(edge: .top).combined(with: .opacity))
                            } else {
                                Button(
                                    action: { onEventTap?() },
                                    label: { emptyEventCard }
                                )
                                .buttonStyle(PlainButtonStyle())
                                .padding(.horizontal, 20)
                            }
                        }

                        if !viewModel.currentEventBills.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("ЧЕКИ")
                                    .font(.system(size: 13, weight: .semibold))
                                    .tracking(1.2)
                                    .foregroundStyle(AppTheme.textSecondary)
                                    .padding(.horizontal, 20)

                                VStack(spacing: 8) {
                                    ForEach(viewModel.currentEventBills) { bill in
                                        BillRowView(bill: bill, onDelete: {}, onTap: {
                                            onBillTap?(bill.id)
                                        })
                                            .transition(.move(edge: .top).combined(with: .opacity))
                                    }
                                }
                                .padding(.horizontal, 20)
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

    private var emptyEventCard: some View {
        GlassCard(padding: 14) {
            HStack(spacing: 12) {
                Text("➕")
                    .font(.system(size: 28))
                Text("Выбрать событие")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.accent)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppTheme.textSecondary)
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                .stroke(AppTheme.accent.opacity(0.4), lineWidth: 1.5)
        )
    }
}

private struct BalanceCardView: View {
    let summary: EventBalanceSummary

    var body: some View {
        GlassCard(padding: 24) {
            VStack(alignment: .center, spacing: 8) {
                Text("Общий баланс")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)
                Text(summary.totalBalance.euroText(signed: true, minimumFractionDigits: 2))
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.accentGradient)
                    .shadow(color: AppTheme.accent.opacity(0.25), radius: 12, x: 0, y: 4)
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
        viewModel: EventsHomeViewModel(
            service: EventManagementService(eventsRepository: EventsDataRepository())
        ),
        onScanTap: {},
        onAddTap: {},
        onBillTap: nil,
        onEventTap: { _ in }
    )
}
