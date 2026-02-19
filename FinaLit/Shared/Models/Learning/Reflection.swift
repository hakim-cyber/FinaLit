//
//  Reflection.swift
//  FinaLit
//

import Foundation
import FirebaseFirestore

struct Reflection: Codable {
    @DocumentID var id: String?
    var weekNumber: Int
    var weekTitle: String
    var content: String
    var submittedAt: Date
}
