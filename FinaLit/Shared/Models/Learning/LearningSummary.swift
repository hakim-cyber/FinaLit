//
//  LearningSummary.swift
//  FinaLit
//

import Foundation

struct LearningSummary: Codable {
    var totalLessonsRead: Int = 0
    var totalQuizzesDone: Int = 0
    var totalWeeksCompleted: Int = 0
    var averageQuizScore: Double = 0.0
    var currentStreak: Int = 0
    var longestStreak: Int = 0
    var lastActiveDate: Date? = nil

    var learningLevel: LearningLevel {
        switch totalWeeksCompleted {
        case 0:
            return .beginner
        case 1...2:
            return .learner
        case 3...5:
            return .skilled
        default:
            return .financialThinker
        }
    }
}
