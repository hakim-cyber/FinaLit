//
//  AnswerRow.swift
//  FinaLit
//

import SwiftUI

struct AnswerRow: View {
    let label: String
    let text: String
    let correct: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: correct ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundStyle(correct ? AppTheme.success : AppTheme.danger)
                .font(.system(size: 14))
            VStack(alignment: .leading, spacing: 2) {
                Text(label.uppercased())
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(AppTheme.textSecondary)
                Text(text)
                    .font(.system(size: 14))
                    .foregroundStyle(correct ? AppTheme.success : AppTheme.danger)
            }
        }
    }
}
