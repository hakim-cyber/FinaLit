//
//  LevelBadge.swift
//  FinaLit
//

import SwiftUI

struct LevelBadge: View {
    let level: LearningLevel

    private var levelColor: String {
        switch level {
        case .beginner: return "6B7280"
        case .learner: return "6366F1"
        case .skilled: return "10B981"
        case .financialThinker: return "FACC15"
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
                    .foregroundStyle(Color(hex: "4B5563"))
                Text(level.rawValue)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(Color(hex: levelColor))
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(hex: levelColor).opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(hex: levelColor).opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal, 20)
    }
}
