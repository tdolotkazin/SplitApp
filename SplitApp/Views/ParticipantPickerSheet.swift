//
//  ParticipantPickerSheet.swift
//  SplitApp
//
//  Created by Claude Code
//

import SwiftUI

struct ParticipantPickerSheet: View {
    let participants: [Participant]
    let onSelect: (Participant) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            // Фон
            AppTheme.backgroundGradient
                .ignoresSafeArea()

            VStack(spacing: 20) {
                // Заголовок
                HStack {
                    Text("Выберите участника")
                        .font(AppTheme.fontTitle)
                        .foregroundStyle(AppTheme.textPrimary)
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)

                // Список участников
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(Array(participants.enumerated()), id: \.element.id) { index, participant in
                            Button(action: {
                                onSelect(participant)
                            }) {
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

                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(AppTheme.textTertiary)
                                }
                                .padding(16)
                                .background(.ultraThinMaterial)
                                .background(AppTheme.cardBackground)
                                .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
                                .overlay(
                                    RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                                        .stroke(AppTheme.cardBorder, lineWidth: 1)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                            .staggeredAppear(index: index)
                        }
                    }
                    .padding(.horizontal, 20)
                }

                // Кнопка добавления нового участника
                Button(action: {
                    // TODO: Добавить функционал создания нового участника
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20))
                        Text("Добавить участника")
                            .font(AppTheme.fontBodyBold)
                    }
                    .foregroundStyle(AppTheme.accent)
                    .padding(.vertical, 16)
                    .frame(maxWidth: .infinity)
                    .background(Color.white.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                            .stroke(AppTheme.accent.opacity(0.3), lineWidth: 1)
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
    }
}
