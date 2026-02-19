//
//  DayProgress.swift
//  FinaLit
//

import Foundation
import FirebaseFirestore

struct DayProgress: Codable {
    @DocumentID var id: String?
    var dayNumber: Int
    var lessonRead: Bool
    var lessonReadAt: Date?
    var quizCompleted: Bool
    var quizScore: Int?
    var totalQuestions: Int?
    var wrongQuestionIDs: [String]
    var isUnlocked: Bool
    var completedAt: Date?

    var scorePercentage: Double {
        guard let score = quizScore, let total = totalQuestions, total > 0 else { return 0 }
        return (Double(score) / Double(total)) * 100
    }

    var isPassed: Bool { scorePercentage >= 60 }

    var isFullyComplete: Bool { lessonRead && quizCompleted }
}
