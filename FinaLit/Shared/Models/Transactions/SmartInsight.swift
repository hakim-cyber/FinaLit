//
//  SmartInsight.swift
//  FinaLit
//

import Foundation

struct SmartInsight: Identifiable {
    let id = UUID()
    var type: InsightType
    var title: String
    var message: String
    var icon: String
    var tone: AppTone
}
