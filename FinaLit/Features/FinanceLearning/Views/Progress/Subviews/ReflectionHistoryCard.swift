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
                    .foregroundStyle(Color(hex: "4B5563"))
            }
            Text(reflection.content)
                .font(.system(size: 13))
                .foregroundStyle(Color(hex: "6B7280"))
                .lineLimit(3)
                .lineSpacing(3)
        }
        .padding(16)
        .background(Color(hex: "111118"))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(hex: "1F2937"), lineWidth: 1)
        )
        .padding(.horizontal, 20)
    }
}
