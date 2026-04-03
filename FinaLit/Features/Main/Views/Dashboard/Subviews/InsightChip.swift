//
//  InsightChip.swift
//  FinaLit
//

import SwiftUI

struct InsightChip: View {
    let insight: SmartInsight

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: insight.icon)
                .font(.system(size: 13))
                .foregroundStyle(Color(hex: insight.color))
            VStack(alignment: .leading, spacing: 2) {
                Text(insight.title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text(insight.message)
                    .font(.system(size: 10))
                    .foregroundStyle(Color(hex: "6B7280"))
                    .lineLimit(2)
            }
        }
        .padding(12)
        .frame(width: 220, alignment: .leading)
        .background(Color(hex: "111118"))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(hex: insight.color).opacity(0.3), lineWidth: 1)
        )
    }
}
