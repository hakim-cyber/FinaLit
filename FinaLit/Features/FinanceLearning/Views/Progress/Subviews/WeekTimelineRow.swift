//
//  WeekTimelineRow.swift
//  FinaLit
//

import SwiftUI

struct WeekTimelineRow: View {
    let weekProgress: WeekProgress
    let weekTitle: String

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(weekProgress.isCompleted ? Color(hex: "10B981") : Color(hex: "1F2937"))
                    .frame(width: 10, height: 10)
            }
            .frame(width: 24)

            VStack(alignment: .leading, spacing: 3) {
                Text(weekTitle)
                    .font(.system(size: 15))
                    .foregroundStyle(weekProgress.isCompleted ? .white : Color(hex: "4B5563"))
                if let date = weekProgress.completedAt {
                    Text(date.formatted(date: .abbreviated, time: .omitted))
                        .font(.system(size: 11))
                        .foregroundStyle(Color(hex: "6B7280"))
                } else if weekProgress.isUnlocked {
                    Text("In progress")
                        .font(.system(size: 11))
                        .foregroundStyle(Color(hex: "6366F1"))
                } else {
                    Text("Locked")
                        .font(.system(size: 11))
                        .foregroundStyle(Color(hex: "374151"))
                }
            }

            Spacer()

            if weekProgress.isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Color(hex: "10B981"))
                    .font(.system(size: 16))
            } else if weekProgress.isUnlocked {
                Image(systemName: "circle.dotted")
                    .foregroundStyle(Color(hex: "6366F1"))
                    .font(.system(size: 16))
            }
        }
        .padding(.horizontal, 20)
    }
}
