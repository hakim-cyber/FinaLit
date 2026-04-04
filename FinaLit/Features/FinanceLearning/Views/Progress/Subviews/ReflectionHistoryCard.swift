//
//  ReflectionHistoryCard.swift
//  FinaLit
//

import SwiftUI

struct ReflectionHistoryCard: View {
    let reflection: Reflection

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(reflection.weekTitle)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                Spacer()
                Text(reflection.submittedAt.formatted(date: .abbreviated, time: .omitted))
                    .font(.system(size: 11))
                    .foregroundStyle(AppTheme.textSecondary)
            }
            Text(reflection.content)
                .font(.system(size: 13))
                .foregroundStyle(AppTheme.textSecondary)
                .lineLimit(3)
                .lineSpacing(3)
        }
        .padding(16)
        .background(AppTheme.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppTheme.separator, lineWidth: 1)
        )
        .padding(.horizontal, 20)
    }
}
