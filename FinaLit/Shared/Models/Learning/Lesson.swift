//
//  Lesson.swift
//  FinaLit
//

import Foundation
import FirebaseFirestore

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
