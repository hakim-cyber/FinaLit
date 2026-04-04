//
//  FilterPill.swift
//  FinaLit
//

import SwiftUI

struct FilterPill: View {
    let label: String
    let isActive: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(label)
                .font(AppTheme.Typography.caption)
                .foregroundStyle(isActive ? AppTheme.inverseText : AppTheme.textSecondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isActive ? AppTheme.accent : AppTheme.surfacePrimary)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(isActive ? Color.clear : AppTheme.separator, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}
