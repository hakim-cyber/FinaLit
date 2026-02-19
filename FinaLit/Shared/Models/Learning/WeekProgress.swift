//
//  WeekProgress.swift
//  FinaLit
//

import Foundation
import FirebaseFirestore

struct WeekProgress: Codable,Identifiable  {
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
