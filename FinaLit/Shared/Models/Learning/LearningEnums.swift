//
//  LearningEnums.swift
//  FinaLit
//

import Foundation

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
