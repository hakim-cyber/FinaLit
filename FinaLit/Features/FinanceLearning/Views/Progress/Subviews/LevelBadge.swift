//
//  LevelBadge.swift
//  FinaLit
//

import SwiftUI

struct LevelBadge: View {
    let level: LearningLevel

    private var tone: AppTone {
        switch level {
        case .beginner: return .slate
        case .learner: return .accent
        case .skilled: return .success
        case .financialThinker: return .warning
        }
    }

    private var levelEmoji: String {
        switch level {
        case .beginner: return "🌱"
        case .learner: return "📈"
        case .skilled: return "💡"
        case .financialThinker: return "🏆"
        }
    }

    var body: some View {
        HStack(spacing: 16) {
            Text(levelEmoji)
                .font(.system(size: 36))
            VStack(alignment: .leading, spacing: 4) {
                Text("YOUR LEVEL")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(AppTheme.textSecondary)
                Text(level.rawValue)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(AppTheme.tint(for: tone))
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.softFill(for: tone))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppTheme.softBorder(for: tone), lineWidth: 1)
        )
        .padding(.horizontal, 20)
    }
}
