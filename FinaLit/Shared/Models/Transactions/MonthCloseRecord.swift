//
//  MonthCloseRecord.swift
//  FinaLit
//

import Foundation
import FirebaseFirestore

struct MonthCloseRecord: Codable, Identifiable {
    @DocumentID var id: String?
    var month: String
    var closedAt: Date
    var rolledToMonth: String
}
