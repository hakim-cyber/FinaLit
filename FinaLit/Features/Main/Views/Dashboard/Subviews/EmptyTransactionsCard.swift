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
            Text(L10n.Main.noTransactionsYet)
                .font(.system(size: 16))
                .foregroundStyle(AppTheme.textPrimary)
            Text(L10n.Main.tapToAddYourFirstTransaction)
                .font(.system(size: 12))
                .foregroundStyle(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .appSurface(.primary, padding: 32, cornerRadius: AppTheme.CornerRadius.large)
    }
}
