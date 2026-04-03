//
//  ScoreCard.swift
//  FinaLit
//

import SwiftUI

struct ScoreCard: View {
    let score: Int
    let total: Int
    let passed: Bool

    private var percentage: Int {
        total > 0 ? Int((Double(score) / Double(total)) * 100) : 0
    }

    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 6) {
                Text("\(score)/\(total)")
                    .font(.system(size: 56, weight: .medium))
                    .foregroundStyle(.white)
                Text("\(percentage)% correct")
                    .font(.system(size: 14))
                    .foregroundStyle(passed ? Color(hex: "10B981") : Color(hex: "F87171"))
            }

            HStack(spacing: 6) {
                Circle()
                    .fill(passed ? Color(hex: "10B981") : Color(hex: "F87171"))
                    .frame(width: 8, height: 8)
                Text(passed ? "Day Complete — Next day unlocked" : "Keep studying — You'll get it!")
                    .font(.system(size: 12))
                    .foregroundStyle(passed ? Color(hex: "10B981") : Color(hex: "F87171"))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background((passed ? Color(hex: "10B981") : Color(hex: "F87171")).opacity(0.1))
            .clipShape(Capsule())
        }
        .frame(maxWidth: .infinity)
        .padding(28)
        .background(Color(hex: "111118"))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    passed ? Color(hex: "10B981").opacity(0.3) : Color(hex: "F87171").opacity(0.3),
                    lineWidth: 1.5
                )
        )
        .padding(.horizontal, 20)
    }
}
