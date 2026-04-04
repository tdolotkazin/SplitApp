import SwiftUI

struct AmountField: View {
    @Binding var amount: Decimal
    var currency: String = "€"

    @FocusState private var isFocused: Bool

    private var amountString: Binding<String> {
        Binding(
            get: {
                if amount == 0 {
                    return ""
                }
                return NSDecimalNumber(decimal: amount).stringValue
            },
            set: { newValue in
                if let decimal = Decimal(string: newValue.replacingOccurrences(of: ",", with: ".")) {
                    amount = decimal
                } else if newValue.isEmpty {
                    amount = 0
                }
            }
        )
    }

    var body: some View {
        HStack(spacing: 4) {
            Text(currency)
                .font(AppTheme.fontBody)
                .foregroundStyle(AppTheme.textSecondary)

            TextField("0", text: amountString)
                .font(AppTheme.fontBody)
                .foregroundStyle(AppTheme.textPrimary)
                .keyboardType(.decimalPad)
                .focused($isFocused)
                .multilineTextAlignment(.leading)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.white.opacity(isFocused ? 0.1 : 0.05))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSmall))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSmall)
                .stroke(isFocused ? AppTheme.accent : Color.clear, lineWidth: 1.5)
        )
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isFocused)
    }
}
