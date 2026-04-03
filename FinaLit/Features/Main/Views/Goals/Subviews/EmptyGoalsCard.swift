//
//  EmptyGoalsCard.swift
//  FinaLit
//

import SwiftUI

struct EmptyGoalsCard: View {
    var body: some View {
        VStack(spacing: 14) {
            Text("🎯")
                .font(.system(size: 40))
            Text("No goals yet")
                .font(.system(size: 18))
                .foregroundStyle(.white)
            Text("Set a financial goal to track your progress.")
                .font(.system(size: 13))
                .foregroundStyle(Color(hex: "4B5563"))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .background(Color(hex: "111118"))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(hex: "1F2937"), lineWidth: 1)
        )
    }
}
