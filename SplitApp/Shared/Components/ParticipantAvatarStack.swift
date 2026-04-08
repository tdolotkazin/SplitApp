import SwiftUI

struct ParticipantAvatarStack: View {
    let participants: [Participant]
    var avatarSize: CGFloat = 28
    var maxVisible: Int = 2

    private var overlap: CGFloat { avatarSize * 0.4 }
    private var visible: [Participant] { Array(participants.prefix(maxVisible)) }

    var body: some View {
        ZStack(alignment: .leading) {
            ForEach(Array(visible.enumerated()), id: \.element.id) { index, participant in
                ParticipantAvatar(participant: participant, size: avatarSize)
                    .offset(x: CGFloat(index) * (avatarSize - overlap))
                    .zIndex(Double(maxVisible - index))
                    .overlay(
                        Circle()
                            .stroke(AppTheme.cardBackground, lineWidth: 1.5)
                            .frame(width: avatarSize, height: avatarSize)
                            .offset(x: CGFloat(index) * (avatarSize - overlap))
                            .zIndex(Double(maxVisible - index) + 0.5),
                        alignment: .leading
                    )
            }
        }
        .frame(
            width: avatarSize + CGFloat(max(visible.count - 1, 0)) * (avatarSize - overlap),
            height: avatarSize
        )
    }
}
