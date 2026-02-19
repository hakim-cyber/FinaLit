//
//  Quiz.swift
//  FinaLit
//

import Foundation
import FirebaseFirestore

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
