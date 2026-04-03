//
//  QuizProgressBar.swift
//  FinaLit
//

import SwiftUI

struct QuizProgressBar: View {
    let current: Int
    let total: Int

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Question \(current) of \(total)")
                    .font(.system(size: 12))
                    .foregroundStyle(Color(hex: "6B7280"))
                Spacer()
            }
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color(hex: "1F2937"))
                        .frame(height: 3)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color(hex: "6366F1"))
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
