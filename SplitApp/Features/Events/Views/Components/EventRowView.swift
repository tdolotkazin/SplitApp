import SwiftUI

struct EventRowView: View {
    let event: EventListItem

    var body: some View {
        HStack(spacing: 12) {
            Text(event.emoji)
                .font(.system(size: 24))
                .frame(width: 40, height: 40)

            VStack(alignment: .leading, spacing: 3) {
                Text(event.title)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color(.label))
                    .multilineTextAlignment(.leading)
                    .padding(.vertical, 2)
                Text(event.subtitle)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(Color(.secondaryLabel))
                    .multilineTextAlignment(.leading)
            }

            Spacer()

            Text(amountLabel)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(amountColor)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
    }

    private var amountLabel: String {
        switch event.tone {
        case .positive:
            return event.amount.euroText(signed: true, minimumFractionDigits: 0)
        case .negative:
            return event.amount.euroText(signed: true, minimumFractionDigits: 0)
        case .neutral:
            return "Закрыт"
        }
    }

    private var amountColor: Color {
        switch event.tone {
        case .positive:
            return Color(red: 0.17, green: 0.76, blue: 0.32)
        case .negative:
            return Color(red: 0.92, green: 0.29, blue: 0.29)
        case .neutral:
            return Color(.secondaryLabel)
        }
    }
}
