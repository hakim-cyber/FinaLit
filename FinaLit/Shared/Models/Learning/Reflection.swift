//
//  Reflection.swift
//  FinaLit
//

import Foundation
import FirebaseFirestore

struct Reflection: Codable,Identifiable  {
    @DocumentID var id: String?
    var weekNumber: Int
    var weekTitle: String
    var content: String
    var submittedAt: Date
}
