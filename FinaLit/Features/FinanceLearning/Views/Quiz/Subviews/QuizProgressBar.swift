//
//  QuizProgressBar.swift
//  FinaLit
//

import SwiftUI

struct QuizProgressBar: View {
    let current: Int
    let total: Int
    @Environment(AppPreferencesStore.self) private var preferences

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(L10n.tr("Question %@ of %@", preferences: preferences, String(current), String(total)))
                    .font(.system(size: 12))
                    .foregroundStyle(AppTheme.textSecondary)
                Spacer()
            }
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(AppTheme.separator)
                        .frame(height: 3)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(AppTheme.accent)
                        .frame(
                            width: geometry.size.width * CGFloat(current) / CGFloat(total),
                            height: 3
                        )
                        .animation(.easeInOut(duration: 0.4), value: current)
                }
            }
            .frame(height: 3)
        }
    }
}
