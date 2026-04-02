import SwiftUI

struct ReceiptPositionRowView: View {
    let item: ReceiptLineItem
    let amountInput: String
    let participants: [ReceiptParticipant]
    let onTitleChange: (String) -> Void
    let onAmountChange: (String) -> Void
    let onParticipantSelect: (ReceiptParticipant) -> Void

    var body: some View {
        HStack(spacing: 10) {
            TextField(
                "Позиция",
                text: Binding(
                    get: { item.title },
                    set: onTitleChange
                ),
                axis: .vertical
            )
            .lineLimit(1...2)
            .font(.system(size: 17, weight: .medium, design: .rounded))
            .foregroundStyle(Color(.label))
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 2) {
                Text("€")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color(.label))

                TextField(
                    "0",
                    text: Binding(
                        get: { amountInput },
                        set: onAmountChange
                    )
                )
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundStyle(Color(.label))
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
            }
            .frame(width: 70, alignment: .trailing)

            Menu {
                ForEach(participants) { participant in
                    Button {
                        onParticipantSelect(participant)
                    } label: {
                        if item.participant.id == participant.id {
                            Label(participant.name, systemImage: "checkmark")
                        } else {
                            Text(participant.name)
                        }
                    }
                }
            } label: {
                participantChip
            }
            .buttonStyle(.borderless)
            .frame(width: 114, alignment: .trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 11)
    }

    private var participantChip: some View {
        HStack(spacing: 6) {
            Text(item.participant.initials)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(participantInitialsColor)
                .frame(width: 33, height: 33)
                .background(participantToneColor.opacity(0.22))
                .clipShape(Circle())

            Text(item.participant.name)
                .font(.system(size: 17, weight: .medium, design: .rounded))
                .foregroundStyle(Color(.label))

            Image(systemName: "chevron.down")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color(.tertiaryLabel))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var participantToneColor: Color {
        switch colorIndex {
        case 0:
            return Color(red: 0.80, green: 0.55, blue: 0.34)
        case 1:
            return Color(red: 0.29, green: 0.68, blue: 0.56)
        case 2:
            return Color(red: 0.34, green: 0.37, blue: 0.86)
        default:
            return Color(.systemGray3)
        }
    }

    private var participantInitialsColor: Color {
        switch colorIndex {
        case 0:
            return Color(red: 0.58, green: 0.33, blue: 0.16)
        case 1:
            return Color(red: 0.18, green: 0.49, blue: 0.38)
        case 2:
            return Color(red: 0.24, green: 0.26, blue: 0.67)
        default:
            return Color(.secondaryLabel)
        }
    }

    private var colorIndex: Int {
        participants.firstIndex(where: { $0.id == item.participant.id }) ?? 0
    }
}
