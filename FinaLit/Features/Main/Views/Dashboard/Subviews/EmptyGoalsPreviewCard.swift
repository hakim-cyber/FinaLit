//
//  EmptyGoalsPreviewCard.swift
//  FinaLit
//

import SwiftUI

struct EmptyGoalsPreviewCard: View {
    let onCreateGoal: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("No active goals yet")
                .font(.system(size: 15))
                .foregroundStyle(.white)

            Text("Create your first goal and start tracking progress from your dashboard.")
                .font(.system(size: 12))
                .foregroundStyle(Color(hex: "6B7280"))
                .fixedSize(horizontal: false, vertical: true)

            Button(action: onCreateGoal) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                    Text("Create your first goal")
                }
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color(hex: "10B981").opacity(0.2))
                .clipShape(Capsule())
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(hex: "111118"))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color(hex: "1F2937"), lineWidth: 1)
        )
    }
}
