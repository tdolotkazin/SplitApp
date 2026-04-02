//
//  CustomTabBar.swift
//  SplitApp
//
//  Created by Claude Code
//

import SwiftUI

enum TabItem: String, CaseIterable {
    case events = "calendar"
    case friends = "person.2.fill"
    case profile = "person.fill"

    var title: String {
        switch self {
        case .events: return "События"
        case .friends: return "Друзья"
        case .profile: return "Профиль"
        }
    }
}

struct CustomTabBar: View {
    @Binding var selectedTab: TabItem

    var body: some View {
        HStack(spacing: 0) {
            ForEach(TabItem.allCases, id: \.self) { tab in
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = tab
                    }
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: tab.rawValue)
                            .font(.system(size: 24))
                            .foregroundStyle(selectedTab == tab ? AppTheme.accent : AppTheme.textSecondary)

                        if selectedTab == tab {
                            Circle()
                                .fill(AppTheme.accent)
                                .frame(width: 4, height: 4)
                        } else {
                            Circle()
                                .fill(Color.clear)
                                .frame(width: 4, height: 4)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
        .background(.ultraThinMaterial)
        .background(AppTheme.cardBackground)
        .overlay(
            Rectangle()
                .fill(AppTheme.cardBorder)
                .frame(height: 1),
            alignment: .top
        )
    }
}
