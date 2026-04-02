//
//  HeaderRow.swift
//  SplitApp
//
//  Created by Claude Code
//

import SwiftUI

struct HeaderRow: View {
    var body: some View {
        HStack(spacing: 12) {
            Text("ПОЗИЦИЯ")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .tracking(1.2)
                .foregroundStyle(AppTheme.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text("СУММА")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .tracking(1.2)
                .foregroundStyle(AppTheme.textSecondary)
                .frame(width: 80, alignment: .leading)

            Text("КТО")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .tracking(1.2)
                .foregroundStyle(AppTheme.textSecondary)
                .frame(width: 70, alignment: .center)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}
