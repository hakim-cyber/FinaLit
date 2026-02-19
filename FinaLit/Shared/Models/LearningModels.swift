//
//  LearningModels.swift
//  FinaLit
//
//  Created by aplle on 2/19/26.
//

import Foundation
import FirebaseFirestore

struct DailyTip: Codable {
    @DocumentID var id: String?
    var title: String
    var body: String
    var date: Date
    var category: String
}

struct Week: Codable {
    @DocumentID var id: String?
    var weekNumber: Int
    var title: String
    var description: String
    var isPublished: Bool
}

struct Day: Codable {
    @DocumentID var id: String?
    var dayNumber: Int
    var lessonID: String
    var quizID: String
    var isReflection: Bool
}

struct Lesson: Codable {
    @DocumentID var id: String?
    var weekNumber: Int
    var dayNumber: Int
    var category: String
    var title: String
    var conceptDefinition: String
    var whyItMatters: String
    var realLifeExample: String
    var miniCaseScenario: String
    var dailyActionTask: String
    var difficultyLevel: String
}

struct Quiz: Codable {
    @DocumentID var id: String?
    var weekNumber: Int
    var dayNumber: Int
    var questions: [QuizQuestion]
}

struct QuizQuestion: Codable {
    @DocumentID var id: String?
    var questionText: String
    var type: String
    var options: [String]
    var correctIndex: Int
    var explanation: String
}

struct WeekProgress: Codable {
    @DocumentID var id: String?
    var weekID: String
    var weekNumber: Int
    var startedAt: Date?
    var completedAt: Date?
    var isUnlocked: Bool
    var isCompleted: Bool
    var reflectionID: String?

    var isReflectionSubmitted: Bool { reflectionID != nil }
}

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

struct Reflection: Codable {
    @DocumentID var id: String?
    var weekNumber: Int
    var weekTitle: String
    var content: String
    var submittedAt: Date
}

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

enum DifficultyLevel: String, Codable {
    case beginner = "Beginner"
    case intermediate = "Intermediate"
    case advanced = "Advanced"
}

enum QuizQuestionType: String, Codable {
    case multipleChoice = "multipleChoice"
    case scenario = "scenario"
}

enum LearningLevel: String, Codable {
    case beginner = "Beginner"
    case learner = "Learner"
    case skilled = "Skilled"
    case financialThinker = "Financial Thinker"
}
