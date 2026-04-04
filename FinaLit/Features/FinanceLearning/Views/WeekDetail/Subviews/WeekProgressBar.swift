//
//  WeekProgressBar.swift
//  FinaLit
//

import SwiftUI

struct WeekProgressBar: View {
    let weekID: String
    @Environment(LearnViewModel.self) private var learnVM

    private var completedCount: Int {
        let days = learnVM.days(for: weekID).filter { !$0.isReflection }
        return days.filter { day in
            learnVM.dayProgress(for: day.id ?? "", in: weekID)?.isFullyComplete == true
        }.count
    }

    private var totalNonReflection: Int {
        learnVM.days(for: weekID).filter { !$0.isReflection }.count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("\(completedCount) of \(totalNonReflection) days complete")
                    .font(.system(size: 12))
                    .foregroundStyle(AppTheme.textSecondary)
                Spacer()
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(AppTheme.separator)
                        .frame(height: 4)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(
                            LinearGradient(
                                colors: [AppTheme.accent, AppTheme.success],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(
                            width: totalNonReflection > 0
                                ? geometry.size.width * CGFloat(completedCount) / CGFloat(totalNonReflection)
                                : 0,
                            height: 4
                        )
                        .animation(.easeInOut(duration: 0.5), value: completedCount)
                }
            }
            .frame(height: 4)
        }
        .padding(.horizontal, 20)
    }
}
