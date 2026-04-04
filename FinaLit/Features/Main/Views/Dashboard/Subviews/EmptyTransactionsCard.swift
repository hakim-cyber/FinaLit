//
//  EmptyTransactionsCard.swift
//  FinaLit
//

import SwiftUI

struct EmptyTransactionsCard: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("💸")
                .font(.system(size: 36))
            Text("No transactions yet")
                .font(.system(size: 16))
                .foregroundStyle(AppTheme.textPrimary)
            Text("Tap + to add your first transaction")
                .font(.system(size: 12))
                .foregroundStyle(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .appSurface(.primary, padding: 32, cornerRadius: AppTheme.CornerRadius.large)
    }
}
