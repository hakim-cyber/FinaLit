//
//  AdminPages.swift
//  FinaLit
//
//  Created by aplle on 2/20/26.
//


// AdminPages.swift
// Features/Admin/Navigation/

import SwiftUI

enum AdminPages: Coordinatable {
    case home
    case addWeek
    case addDay(String)          // weekID
    case addLesson(String)       // dayID
    case addQuiz(String)         // dayID
    case addDailyTip
    case bulkImport
    case settings

    var id: String {
        switch self {
        case .home:              return "admin.home"
        case .addWeek:           return "admin.addWeek"
        case .addDay(let id):    return "admin.addDay.\(id)"
        case .addLesson(let id): return "admin.addLesson.\(id)"
        case .addQuiz(let id):   return "admin.addQuiz.\(id)"
        case .addDailyTip:       return "admin.addDailyTip"
        case .bulkImport:        return "admin.bulkImport"
        case .settings:          return "admin.settings"
        }
    }

    @ViewBuilder
    var body: some View {
        switch self {
        case .home:              AdminHomeView()
        case .addWeek:           AddWeekView()
        case .addDay(let id):    AddDayView(weekID: id)
        case .addLesson(let id): AddLessonView(dayID: id)
        case .addQuiz(let id):   AddQuizView(dayID: id)
        case .addDailyTip:       AddDailyTipView()
        case .bulkImport:        AddBulkImportView()
        case .settings:          CoordinatorStack(SettingsPages.home)
        }
    }
}
