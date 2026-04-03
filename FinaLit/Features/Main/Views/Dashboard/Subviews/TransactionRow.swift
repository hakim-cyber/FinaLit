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
                    .fill(Color(hex: transaction.category.color).opacity(0.12))
                    .frame(width: 38, height: 38)
                Image(systemName: transaction.category.icon)
                    .font(.system(size: 14))
                    .foregroundStyle(Color(hex: transaction.category.color))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.note.isEmpty ? transaction.category.rawValue : transaction.note)
                    .font(.system(size: 14))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text(transaction.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.system(size: 11))
                    .foregroundStyle(Color(hex: "4B5563"))
            }
            Spacer()
            Text(formatSignedCurrency(amount: transaction.amount, isIncome: transaction.isIncome))
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(transaction.isIncome ? Color(hex: "10B981") : .white)
        }
        .padding(12)
    }
}
