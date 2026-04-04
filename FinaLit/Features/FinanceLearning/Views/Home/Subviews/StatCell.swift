//
//  StatCell.swift
//  FinaLit
//

import SwiftUI

struct StatCell: View {
    let value: String
    let label: String
    var small: Bool = false

    var body: some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.system(size: small ? 12 : 18, weight: .semibold))
                .foregroundStyle(AppTheme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(AppTheme.Typography.detail)
                .foregroundStyle(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}
