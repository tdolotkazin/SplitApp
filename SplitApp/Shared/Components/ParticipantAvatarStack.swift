import SwiftUI

struct ParticipantAvatarStack: View {
    let participants: [Participant]
    var avatarSize: CGFloat = 28
    var maxVisible: Int = 2

    private var overlap: CGFloat {
        avatarSize * 0.55
    }

    private var step: CGFloat {
        avatarSize - overlap
    }

    private var visible: [Participant] {
        Array(participants.prefix(maxVisible))
    }

    private var overflow: Int {
        max(0, participants.count - maxVisible)
    }

    var body: some View {
        HStack(spacing: 10) {
            ZStack(alignment: .leading) {
                ForEach(Array(visible.enumerated()), id: \.element.id) { index, participant in
                    ParticipantAvatar(participant: participant, size: avatarSize)
                        .overlay(
                            Circle()
                                .stroke(AppTheme.cardBackground, lineWidth: 1.5)
                                .frame(width: avatarSize, height: avatarSize)
                        )
                        .offset(x: CGFloat(index) * step)
                        .zIndex(Double(maxVisible - index))
                }
            }
            .frame(
                width: avatarSize + CGFloat(max(visible.count - 1, 0)) * step,
                height: avatarSize
            )

            if overflow > 0 {
                Text("+\(overflow)")
                    .font(.system(size: avatarSize * 0.46, weight: .semibold))
                    .foregroundStyle(AppTheme.textSecondary)
                    .fixedSize()
            }
        }
    }
}
