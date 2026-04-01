import SwiftUI

struct ReceiptInputView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: ReceiptInputViewModel

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            VStack(spacing: 12) {
                header
                tableCard
                totalCard
                Spacer(minLength: 0)
                saveButton
            }
            .padding(.horizontal, 16)
            .padding(.top, 6)
            .padding(.bottom, 18)
        }
        .navigationBarHidden(true)
    }

    private var header: some View {
        HStack {
            Button(action: { dismiss() }) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                    Text("Назад")
                }
                .font(.system(size: 17, weight: .medium, design: .rounded))
                .foregroundStyle(Color.accentColor)
            }
            Spacer()
            Text("Ввод чека")
                .font(.system(size: 34, weight: .semibold, design: .rounded))
                .foregroundStyle(Color(.label))
            Spacer()
            Text("Готово")
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundStyle(Color(.tertiaryLabel))
        }
        .padding(.top, 2)
    }

    private var tableCard: some View {
        VStack(spacing: 0) {
            tableHeader

            ForEach(Array(viewModel.lineItems.enumerated()), id: \.element.id) { index, item in
                ReceiptPositionRowView(
                    item: item,
                    participants: viewModel.participants,
                    onTitleChange: { viewModel.updateTitle($0, for: item.id) },
                    onAmountChange: { viewModel.updateAmountInput($0, for: item.id) },
                    onParticipantSelect: { viewModel.setParticipant($0, for: item.id) }
                )

                if index < viewModel.lineItems.count - 1 {
                    Divider()
                }
            }

            Divider()

            Button(action: viewModel.addPosition) {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                    Text("Добавить позицию")
                }
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .foregroundStyle(Color.accentColor)
            }
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var tableHeader: some View {
        HStack {
            Text("ПОЗИЦИЯ")
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("СУММА")
                .frame(width: 90, alignment: .center)
            Text("КТО")
                .frame(width: 112, alignment: .center)
        }
        .font(.system(size: 14, weight: .semibold))
        .foregroundStyle(Color(.secondaryLabel))
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemGray6))
    }

    private var totalCard: some View {
        HStack {
            Text("Итого")
                .font(.system(size: 35, weight: .semibold, design: .rounded))
                .foregroundStyle(Color(.label))
            Spacer()
            Text(viewModel.totalAmount.euroText(minimumFractionDigits: 2))
                .font(.system(size: 39, weight: .bold, design: .rounded))
                .foregroundStyle(Color.accentColor)
        }
        .padding(.horizontal, 16)
        .frame(height: 90)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var saveButton: some View {
        Button(action: {}) {
            Text("Сохранить")
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 88)
                .background(Color.accentColor)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
    }
}

#Preview {
    ReceiptInputView(viewModel: .mock())
}
