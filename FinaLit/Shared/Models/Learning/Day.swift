//
//  Day.swift
//  FinaLit
//

import Foundation
import FirebaseFirestore

struct Day: Codable {
    @DocumentID var id: String?
    var dayNumber: Int
    var lessonID: String
    var quizID: String
    var isReflection: Bool
}
