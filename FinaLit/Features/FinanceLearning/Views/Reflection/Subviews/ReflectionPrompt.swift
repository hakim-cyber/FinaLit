//
//  ReflectionPrompt.swift
//  FinaLit
//

import SwiftUI

struct ReflectionPrompt: View {
    let number: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(AppTheme.accent)
                .padding(.top, 2)
            Text(text)
                .font(.system(size: 14))
                .foregroundStyle(AppTheme.textSecondary)
                .lineSpacing(3)
        }
        .padding(14)
        .background(AppTheme.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
