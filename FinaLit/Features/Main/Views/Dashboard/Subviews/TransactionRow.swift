//
//  TransactionRow.swift
//  FinaLit
//

import SwiftUI

struct TransactionRow: View {
    let transaction: Transaction

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(AppTheme.softFill(for: transaction.category.tone))
                    .frame(width: 38, height: 38)
                Image(systemName: transaction.category.icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppTheme.tint(for: transaction.category.tone))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.note.isEmpty ? transaction.category.rawValue : transaction.note)
                    .font(AppTheme.Typography.bodySemibold)
                    .foregroundStyle(AppTheme.textPrimary)
                    .lineLimit(1)
                Text(transaction.date.formatted(date: .abbreviated, time: .omitted))
                    .font(AppTheme.Typography.detail)
                    .foregroundStyle(AppTheme.textSecondary)
            }
            Spacer()
            Text(formatSignedCurrency(amount: transaction.amount, isIncome: transaction.isIncome))
                .font(AppTheme.Typography.bodySemibold)
                .monospacedDigit()
                .foregroundStyle(transaction.isIncome ? AppTheme.success : AppTheme.textPrimary)
        }
        .padding(12)
    }
}
