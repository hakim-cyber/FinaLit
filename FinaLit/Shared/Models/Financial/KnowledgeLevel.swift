//
//  KnowledgeLevel.swift
//  FinaLit
//

import Foundation

enum KnowledgeLevel: String, Codable, CaseIterable, Identifiable {
    case beginner = "Beginner"
    case intermediate = "Intermediate"
    case advanced = "Advanced"

    var id: String { rawValue }
}
