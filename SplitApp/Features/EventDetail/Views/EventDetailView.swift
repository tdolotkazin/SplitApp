import SwiftUI

struct EventDetailView: View {
    @StateObject var viewModel: EventDetailViewModel
    @Environment(\.dismiss) private var dismiss

    let onAddReceipt: () -> Void
    let onReceiptTap: (UUID) -> Void

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            if viewModel.isLoading && viewModel.event == nil {
                ProgressView("Загрузка...")
                    .font(.system(size: 17, weight: .medium, design: .rounded))
            } else if let errorMessage = viewModel.errorMessage, viewModel.event == nil {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.orange)
                    Text(errorMessage)
                        .font(
                            .system(size: 17, weight: .medium, design: .rounded)
                        )
                        .multilineTextAlignment(.center)
                    Button("Попробовать снова") {
                        Task { await viewModel.load() }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(24)
            } else if let event = viewModel.event {
                VStack(spacing: 0) {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 24) {
                            if viewModel.isShowingCachedDataBanner {
                                HStack(spacing: 10) {
                                    Image(systemName: "wifi.slash")
                                        .foregroundStyle(.orange)
                                    Text("Показываем сохранённые данные. Для обновления нужен интернет.")
                                        .font(.system(size: 14, weight: .medium, design: .rounded))
                                        .foregroundStyle(Color(.secondaryLabel))
                                }
                                .padding(14)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(.systemBackground))
                                .clipShape(
                                    RoundedRectangle(
                                        cornerRadius: 16,
                                        style: .continuous
                                    )
                                )
                            }

                            // Header
                            HStack(spacing: 16) {
                                Text(event.icon)
                                    .font(.system(size: 64))
                                    .frame(width: 80, height: 80)
                                    .background(Color(.systemBackground))
                                    .clipShape(
                                        RoundedRectangle(
                                            cornerRadius: 20,
                                            style: .continuous
                                        )
                                    )
                                    .shadow(
                                        color: .black.opacity(0.05),
                                        radius: 10,
                                        x: 0,
                                        y: 5
                                    )

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(event.name)
                                        .font(
                                            .system(
                                                size: 28,
                                                weight: .bold,
                                                design: .rounded
                                            )
                                        )
                                        .foregroundStyle(Color(.label))
                                        .fixedSize(
                                            horizontal: false,
                                            vertical: true
                                        )

                                    Text(
                                        "\(event.participantsCount) участников"
                                    )
                                    .font(
                                        .system(
                                            size: 17,
                                            weight: .medium,
                                            design: .rounded
                                        )
                                    )
                                    .foregroundStyle(Color(.secondaryLabel))
                                }
                            }
                            .padding(.top, 12)

                            // Info Card
                            VStack(spacing: 0) {
                                InfoRow(
                                    title: "Дата создания",
                                    value: formatDate(event.date)
                                )
                                Divider().padding(.leading, 16)
                                InfoRow(
                                    title: "Ваш баланс",
                                    value: event.balanceDelta.euroText(
                                        signed: true,
                                        minimumFractionDigits: 2
                                    ),
                                    valueColor: balanceColor(event.balanceDelta)
                                )
                            }
                            .background(Color(.systemBackground))
                            .clipShape(
                                RoundedRectangle(
                                    cornerRadius: 20,
                                    style: .continuous
                                )
                            )

                            // Receipts Section
                            VStack(alignment: .leading, spacing: 12) {
                                Text("ЧЕКИ")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(Color(.secondaryLabel))
                                    .padding(.leading, 4)

                                if viewModel.receipts.isEmpty {
                                    Text("Чеков пока нет")
                                        .font(
                                            .system(
                                                size: 17,
                                                weight: .medium,
                                                design: .rounded
                                            )
                                        )
                                        .foregroundStyle(Color(.secondaryLabel))
                                        .frame(
                                            maxWidth: .infinity,
                                            alignment: .center
                                        )
                                        .padding(.vertical, 32)
                                        .background(Color(.systemBackground))
                                        .clipShape(
                                            RoundedRectangle(
                                                cornerRadius: 20,
                                                style: .continuous
                                            )
                                        )
                                } else {
                                    VStack(spacing: 12) {
                                        ForEach(viewModel.receipts) { receipt in
                                            ReceiptRowView(receipt: receipt) {
                                                onReceiptTap(receipt.id)
                                            }
                                        }
                                    }
                                }
                            }

                            Spacer()
                                .frame(height: 100)
                        }
                        .padding(18)
                    }
                }
                .overlay(alignment: .bottomTrailing) {
                    Button(action: onAddReceipt) {
                        Image(systemName: "plus")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 64, height: 64)
                            .background(Color.accentColor)
                            .clipShape(Circle())
                            .shadow(
                                color: Color.accentColor.opacity(0.3),
                                radius: 10,
                                x: 0,
                                y: 5
                            )
                    }
                    .padding(24)
                }
                .overlay(alignment: .top) {
                    if viewModel.isLoading {
                        ProgressView()
                            .padding(.top, 12)
                    }
                }
            }
        }
        .navigationTitle("Детали события")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.accentColor)
                }
            }
        }
        .task {
            await viewModel.load()
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter.string(from: date)
    }

    private func balanceColor(_ amount: Double) -> Color {
        if amount > 0 { return Color(red: 0.17, green: 0.76, blue: 0.32) }
        if amount < 0 { return Color(red: 0.92, green: 0.29, blue: 0.29) }
        return Color(.secondaryLabel)
    }
}

private struct InfoRow: View {
    let title: String
    let value: String
    var valueColor: Color = Color(.label)

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 17, weight: .medium, design: .rounded))
                .foregroundStyle(Color(.secondaryLabel))
            Spacer()
            Text(value)
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundStyle(valueColor)
        }
        .padding(16)
    }
}
