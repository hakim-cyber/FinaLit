//
//  DailyTip.swift
//  FinaLit
//

import Foundation
import FirebaseFirestore

struct DailyTip: Codable ,Identifiable {
    @DocumentID var id: String?
    var title: String
    var body: String
    var date: Date
    var category: String
}
