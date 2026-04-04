//
//  StatusDot.swift
//  FinaLit
//

import SwiftUI

struct StatusDot: View {
    let done: Bool
    let label: String

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(done ? AppTheme.success : AppTheme.textTertiary)
                .frame(width: 5, height: 5)
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(done ? AppTheme.success : AppTheme.textSecondary)
        }
    }
}
