import SwiftUI

struct ReceiptInputView: View {
    @ObservedObject var viewModel: ReceiptInputViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Navigation bar
                HStack {
                    Button(
                        action: { dismiss() },
                        label: {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 17, weight: .semibold))
                                Text("Назад")
                                    .font(.system(size: 17))
                            }
                            .foregroundStyle(Color.accentColor)
                        }
                    )

                    Spacer()

                    Text("Позиции")
                        .font(.system(size: 17, weight: .semibold))

                    Spacer()

                    Button(
                        action: { dismiss() },
                        label: {
                            Text("Готово")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(Color.accentColor)
                        }
                    )
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 12)
                .background(Color(.systemBackground))

                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(viewModel.lineItems.enumerated()), id: \.element.id) { index, item in
                            ReceiptLineItemRow(
                                item: item,
                                amountInput: viewModel.amountInput(for: item.id),
                                onTitleChange: { viewModel.updateTitle($0, at: index) },
                                onAmountChange: { viewModel.updateAmountInput($0, at: index) }
                            )

                            if index < viewModel.lineItems.count - 1 {
                                Divider()
                                    .padding(.leading, 18)
                            }
                        }
                    }
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .padding(.horizontal, 18)
                    .padding(.top, 18)

                    Button(
                        action: { viewModel.addPosition() },
                        label: {
                            HStack(spacing: 8) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 20))
                                Text("Добавить позицию")
                                    .font(.system(size: 17, weight: .medium))
                            }
                            .foregroundStyle(Color.accentColor)
                            .padding(.vertical, 14)
                            .frame(maxWidth: .infinity)
                            .background(Color(.systemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                    )
                    .padding(.horizontal, 18)
                    .padding(.top, 12)

                    Color.clear.frame(height: 100)
                }

                // Total bar
                HStack {
                    Text("Итого")
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color(.label))
                    Spacer()
                    Text(viewModel.totalAmount.euroText)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.accentColor)
                        .contentTransition(.numericText())
                }
                .padding(.horizontal, 22)
                .padding(.vertical, 18)
                .background(Color(.systemBackground))
            }

            if viewModel.isScanning {
                ZStack {
                    Color.black.opacity(0.35)
                        .ignoresSafeArea()

                    VStack(spacing: 16) {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.white)
                            .scaleEffect(1.4)

                        Text("Распознаю чек…")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundStyle(.white)
                    }
                    .padding(28)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                }
                .transition(.opacity.animation(.easeInOut(duration: 0.2)))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: viewModel.isScanning)
    }
}

// MARK: - Line Item Row

private struct ReceiptLineItemRow: View {
    let item: ReceiptLineItem
    let amountInput: String
    let onTitleChange: (String) -> Void
    let onAmountChange: (String) -> Void

    @State private var title: String
    @State private var amount: String

    init(
        item: ReceiptLineItem,
        amountInput: String,
        onTitleChange: @escaping (String) -> Void,
        onAmountChange: @escaping (String) -> Void
    ) {
        self.item = item
        self.amountInput = amountInput
        self.onTitleChange = onTitleChange
        self.onAmountChange = onAmountChange
        _title = State(initialValue: item.title)
        _amount = State(initialValue: amountInput)
    }

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(item.participant.color.opacity(0.2))
                .frame(width: 10, height: 10)

            TextField("Название", text: $title)
                .font(.system(size: 17))
                .onChange(of: title) { _, newValue in onTitleChange(newValue) }
                .frame(maxWidth: .infinity)

            TextField("0", text: $amount)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(Color.accentColor)
                .multilineTextAlignment(.trailing)
                .keyboardType(.decimalPad)
                .frame(width: 80)
                .onChange(of: amount) { _, newValue in onAmountChange(newValue) }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
    }
}

// MARK: - Helpers

private extension Double {
    var euroText: String {
        if self == 0 { return "€0" }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "€"
        formatter.maximumFractionDigits = self.truncatingRemainder(dividingBy: 1) == 0 ? 0 : 2
        return formatter.string(from: NSNumber(value: self)) ?? "€\(self)"
    }
}
