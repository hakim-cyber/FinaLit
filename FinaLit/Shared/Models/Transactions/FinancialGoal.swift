//
//  FinancialGoal.swift
//  FinaLit
//

import Foundation
import FirebaseFirestore

struct FinancialGoal: Codable, Identifiable {
    @DocumentID var id: String?
    var title: String
    var targetAmount: Double
    var currentAmount: Double
    var deadline: Date?
    var isCompleted: Bool = false
    var createdAt: Date

    var progressPercentage: Double {
        guard targetAmount > 0 else { return 0 }
        return min((currentAmount / targetAmount) * 100, 100)
    }

    var isOnTrack: Bool {
        guard let deadline else { return true }
        let monthsLeft = Calendar.current.dateComponents([.month], from: Date(), to: deadline).month ?? 0
        guard monthsLeft > 0 else { return currentAmount >= targetAmount }
        let neededPerMonth = (targetAmount - currentAmount) / Double(monthsLeft)
        return neededPerMonth > 0
    }
}
