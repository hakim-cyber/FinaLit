//
//  RecurringFrequency.swift
//  FinaLit
//

import Foundation

enum RecurringFrequency: String, Codable, CaseIterable, Identifiable {
    case weekly = "Weekly"
    case monthly = "Monthly"
    case yearly = "Yearly"

    var id: String { rawValue }
}
