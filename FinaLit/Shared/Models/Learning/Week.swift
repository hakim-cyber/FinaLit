//
//  Week.swift
//  FinaLit
//

import Foundation
import FirebaseFirestore

struct Week: Codable,Identifiable {
    @DocumentID var id: String?
    var weekNumber: Int
    var title: String
    var description: String
    var isPublished: Bool
}
