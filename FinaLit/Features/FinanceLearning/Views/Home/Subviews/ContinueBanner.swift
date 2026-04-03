//
//  ContinueBanner.swift
//  FinaLit
//

import SwiftUI

struct ContinueBanner: View {
    let weekID: String
    let dayID: String
    let dayNumber: Int

    @Environment(Coordinator<LearnPages>.self) private var coordinator
    @Environment(LearnViewModel.self) private var learnVM

    var body: some View {
        Button {
            let days = learnVM.days(for: weekID)
            if let day = days.first(where: { $0.id == dayID }) {
                if day.isReflection {
                    let week = learnVM.publishedWeeks.first { $0.id == weekID }
                    coordinator.push(.reflection(weekID, week?.title ?? ""))
                } else {
                    coordinator.push(.lessonDetail(day.lessonID, dayID))
                }
            }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("CONTINUE WHERE YOU LEFT OFF")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Color(hex: "6366F1"))
                    Text("Day \(dayNumber)")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                }
                Spacer()
                Image(systemName: "arrow.right.circle.fill")
                    .font(.title2)
                    .foregroundStyle(Color(hex: "6366F1"))
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(hex: "111118"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color(hex: "6366F1").opacity(0.4), lineWidth: 1)
                    )
            )
        }
        .padding(.horizontal, 20)
    }
}
