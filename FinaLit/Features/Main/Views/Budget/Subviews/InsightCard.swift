//
//  InsightCard.swift
//  FinaLit
//

import SwiftUI

struct InsightCard: View {
    let insight: SmartInsight

    private var bgColor: Color {
        switch insight.type {
        case .danger: return Color(hex: "F87171").opacity(0.06)
        case .warning: return Color(hex: "FACC15").opacity(0.06)
        case .positive: return Color(hex: "10B981").opacity(0.06)
        case .info: return Color(hex: "6366F1").opacity(0.06)
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color(hex: insight.color).opacity(0.15))
                    .frame(width: 38, height: 38)
                Image(systemName: insight.icon)
                    .font(.system(size: 15))
                    .foregroundStyle(Color(hex: insight.color))
            }
            VStack(alignment: .leading, spacing: 5) {
                Text(insight.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                Text(insight.message)
                    .font(.system(size: 12))
                    .foregroundStyle(Color(hex: "6B7280"))
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .background(bgColor)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color(hex: insight.color).opacity(0.2), lineWidth: 1)
        )
    }
}
