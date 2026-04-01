import SwiftUI

struct ReceiptPositionRowView: View {
    let item: ReceiptLineItem
    let participants: [ReceiptParticipant]
    let onTitleChange: (String) -> Void
    let onAmountChange: (String) -> Void
    let onParticipantSelect: (ReceiptParticipant?) -> Void

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
                .foregroundStyle(item.isPlaceholder ? Color(.tertiaryLabel) : Color(.label))
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 2) {
                Text("€")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(item.isPlaceholder ? Color(.tertiaryLabel) : Color(.label))
                TextField(
                    "0",
                    text: Binding(
                        get: { item.amountInput },
                        set: onAmountChange
                    )
                )
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundStyle(item.isPlaceholder ? Color(.tertiaryLabel) : Color(.label))
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
            }
                .frame(width: 70, alignment: .trailing)

            Menu {
                Button {
                    onParticipantSelect(nil)
                } label: {
                    if item.participant == nil {
                        Label("Не выбрано", systemImage: "checkmark")
                    } else {
                        Text("Не выбрано")
                    }
                }

                ForEach(participants) { participant in
                    Button {
                        onParticipantSelect(participant)
                    } label: {
                        if item.participant?.id == participant.id {
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

    @ViewBuilder
    private var participantChip: some View {
        if let participant = item.participant {
            HStack(spacing: 6) {
                Text(participant.initials)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(participantInitialsColor)
                    .frame(width: 33, height: 33)
                    .background(participantToneColor.opacity(0.22))
                    .clipShape(Circle())

                Text(participant.name)
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
        } else {
            HStack(spacing: 4) {
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .bold))
                Text("Кто?")
                    .font(.system(size: 17, weight: .medium, design: .rounded))
                Image(systemName: "chevron.down")
                    .font(.system(size: 14, weight: .semibold))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .foregroundStyle(Color(.tertiaryLabel))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [5, 3]))
                    .foregroundStyle(Color(.quaternaryLabel))
            }
        }
    }

    private var participantToneColor: Color {
        guard let participant = item.participant else { return Color(.systemGray3) }

        switch participant.tone {
        case .orange:
            return Color(red: 0.80, green: 0.55, blue: 0.34)
        case .mint:
            return Color(red: 0.29, green: 0.68, blue: 0.56)
        case .indigo:
            return Color(red: 0.34, green: 0.37, blue: 0.86)
        case .neutral:
            return Color(.systemGray3)
        }
    }

    private var participantInitialsColor: Color {
        guard let participant = item.participant else { return Color(.tertiaryLabel) }

        switch participant.tone {
        case .orange:
            return Color(red: 0.58, green: 0.33, blue: 0.16)
        case .mint:
            return Color(red: 0.18, green: 0.49, blue: 0.38)
        case .indigo:
            return Color(red: 0.24, green: 0.26, blue: 0.67)
        case .neutral:
            return Color(.secondaryLabel)
        }
    }
}
