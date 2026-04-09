import Foundation

extension Double {
    func rubleText(signed: Bool = false, minimumFractionDigits: Int = 0, maximumFractionDigits: Int = 2) -> String {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = minimumFractionDigits
        formatter.maximumFractionDigits = maximumFractionDigits

        let valueToFormat = abs(self)
        let number = NSNumber(value: valueToFormat)
        let amount = formatter.string(from: number) ?? String(valueToFormat)

        if signed {
            if self > 0 {
                return "+₽\(amount)"
            }
            if self < 0 {
                return "-₽\(amount)"
            }
        }

        return "₽\(amount)"
    }
}
