import SwiftUI

struct ParticipantPickerSheet: View {
    let participants: [Participant]
    let selectedParticipants: [Participant]
    let onToggle: (Participant) -> Void
    let onDone: () -> Void
    let selectedParticipants: [Participant]
    let onToggle: (Participant) -> Void
    let onDone: () -> Void

    @Environment(\.dismiss) private var dismiss

    private func isSelected(_ participant: Participant) -> Bool {
        selectedParticipants.contains(where: { $0.id == participant.id })
    }

    private func isSelected(_ participant: Participant) -> Bool {
        selectedParticipants.contains(where: { $0.id == participant.id })
    }

    var body: some View {
        ZStack {
            AppTheme.backgroundGradient
                .ignoresSafeArea()

            VStack(spacing: 20) {
                HStack {
                    Text("Назначить участников")
                    Text("Назначить участников")
                        .font(AppTheme.fontTitle)
                        .foregroundStyle(AppTheme.textPrimary)
                    Spacer()
                    Button(
                        action: { onDone() },
                        action: { onDone() },
                        label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 24))
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                    )
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)

                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(Array(participants.enumerated()), id: \.element.id) { index, participant in
                            let selected = isSelected(participant)
                            Button(
                                action: {
                                    onToggle(participant)
                                    onToggle(participant)
                                },
                                label: {
                                    HStack(spacing: 16) {
                                        ParticipantAvatar(participant: participant, size: 48)

                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(participant.name)
                                                .font(AppTheme.fontBodyBold)
                                                .foregroundStyle(AppTheme.textPrimary)
                                            Text(participant.initials)
                                                .font(.system(size: 14))
                                                .foregroundStyle(AppTheme.textSecondary)
                                        }

                                        Spacer()

                                        Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                                            .font(.system(size: 22, weight: .semibold))
                                            .foregroundStyle(selected ? AppTheme.accent : AppTheme.textTertiary)
                                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selected)
                                        Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                                            .font(.system(size: 22, weight: .semibold))
                                            .foregroundStyle(selected ? AppTheme.accent : AppTheme.textTertiary)
                                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selected)
                                    }
                                    .padding(16)
                                    .background(.ultraThinMaterial)
                                    .background(selected ? AppTheme.accent.opacity(0.08) : AppTheme.cardBackground)
                                    .background(selected ? AppTheme.accent.opacity(0.08) : AppTheme.cardBackground)
                                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                                            .stroke(
                                                selected ? AppTheme.accent.opacity(0.5) : AppTheme.cardBorder,
                                                lineWidth: selected ? 1.5 : 1
                                            )
                                            .stroke(
                                                selected ? AppTheme.accent.opacity(0.5) : AppTheme.cardBorder,
                                                lineWidth: selected ? 1.5 : 1
                                            )
                                    )
                                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selected)
                                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selected)
                                }
                            )
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, 20)
                }

                VStack(spacing: 12) {
                    Button(
                        action: { onDone() },
                        label: {
                            HStack(spacing: 8) {
                                if !selectedParticipants.isEmpty {
                                    Text("Готово (\(selectedParticipants.count))")
                                        .font(AppTheme.fontBodyBold)
                                } else {
                                    Text("Готово")
                                        .font(AppTheme.fontBodyBold)
                                }
                            }
                            .foregroundStyle(.white)
                            .padding(.vertical, 16)
                            .frame(maxWidth: .infinity)
                            .background(
                                selectedParticipants.isEmpty
                                    ? AppTheme.accent.opacity(0.4)
                                    : AppTheme.accent
                            )
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
                        }
                    )
                    .buttonStyle(PlainButtonStyle())

                VStack(spacing: 12) {
                    Button(
                        action: { onDone() },
                        label: {
                            HStack(spacing: 8) {
                                if !selectedParticipants.isEmpty {
                                    Text("Готово (\(selectedParticipants.count))")
                                        .font(AppTheme.fontBodyBold)
                                } else {
                                    Text("Готово")
                                        .font(AppTheme.fontBodyBold)
                                }
                            }
                            .foregroundStyle(.white)
                            .padding(.vertical, 16)
                            .frame(maxWidth: .infinity)
                            .background(
                                selectedParticipants.isEmpty
                                    ? AppTheme.accent.opacity(0.4)
                                    : AppTheme.accent
                            )
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
                        }
                    )
                    .buttonStyle(PlainButtonStyle())

                    Button(
                        action: {},
                        label: {
                            HStack(spacing: 8) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 20))
                                Text("Добавить участника")
                                    .font(AppTheme.fontBodyBold)
                            }
                            .foregroundStyle(AppTheme.accent)
                            .padding(.vertical, 16)
                            .frame(maxWidth: .infinity)
                            .background(AppTheme.surfaceOverlay)
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
                            .overlay(
                                RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                                    .stroke(AppTheme.accent.opacity(0.3), lineWidth: 1)
                            )
                        }
                    )
                    .buttonStyle(PlainButtonStyle())
                }
                    Button(
                        action: {},
                        label: {
                            HStack(spacing: 8) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 20))
                                Text("Добавить участника")
                                    .font(AppTheme.fontBodyBold)
                            }
                            .foregroundStyle(AppTheme.accent)
                            .padding(.vertical, 16)
                            .frame(maxWidth: .infinity)
                            .background(AppTheme.surfaceOverlay)
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
                            .overlay(
                                RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                                    .stroke(AppTheme.accent.opacity(0.3), lineWidth: 1)
                            )
                        }
                    )
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
    }
}
