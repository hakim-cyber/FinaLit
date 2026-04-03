//
//  DailyTipCard.swift
//  FinaLit
//

import SwiftUI

struct DailyTipCard: View {
    let tip: DailyTip
    @State private var expanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("TODAY'S INSIGHT")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Color(hex: "10B981"))
                Spacer()
                Text(tip.category.uppercased())
                    .font(.system(size: 10))
                    .foregroundStyle(Color(hex: "4B5563"))
            }

            Text(tip.title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white)

            if expanded {
                Text(tip.body)
                    .font(.system(size: 14))
                    .foregroundStyle(Color(hex: "9CA3AF"))
                    .lineSpacing(4)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }

            Button(expanded ? "Show less ↑" : "Read more ↓") {
                withAnimation(.easeInOut(duration: 0.2)) { expanded.toggle() }
            }
            .font(.system(size: 12))
            .foregroundStyle(Color(hex: "10B981"))
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(hex: "0D1F17"))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(hex: "10B981").opacity(0.3), lineWidth: 1)
                )
        )
        .padding(.horizontal, 20)
    }
}
