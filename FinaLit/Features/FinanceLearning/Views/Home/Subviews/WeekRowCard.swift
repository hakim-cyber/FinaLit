//
//  WeekRowCard.swift
//  FinaLit
//

import SwiftUI

struct WeekRowCard: View {
    let week: Week
    let progress: WeekProgress?

    private var isLocked: Bool { progress?.isUnlocked != true }
    private var isComplete: Bool { progress?.isCompleted == true }

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        isComplete
                            ? Color(hex: "10B981")
                            : isLocked
                                ? Color(hex: "1F2937")
                                : Color(hex: "6366F1").opacity(0.2)
                    )
                    .frame(width: 44, height: 44)

                if isComplete {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                } else if isLocked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(Color(hex: "374151"))
                } else {
                    Text("\(week.weekNumber)")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color(hex: "6366F1"))
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(week.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(isLocked ? Color(hex: "374151") : .white)
                Text(week.description)
                    .font(.system(size: 12))
                    .foregroundStyle(Color(hex: "4B5563"))
                    .lineLimit(1)
            }

            Spacer()

            if !isLocked {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundStyle(Color(hex: "374151"))
            }
        }
        .padding(16)
        .background(Color(hex: "111118"))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(
                    isComplete ? Color(hex: "10B981").opacity(0.3) : Color(hex: "1F2937"),
                    lineWidth: 1
                )
        )
        .opacity(isLocked ? 0.5 : 1)
        .padding(.horizontal, 20)
    }
}
