//
//  LearnPages.swift
//  FinaLit
//
//  Created by aplle on 2/18/26.
//


// LearnPages.swift
// Features/Learn/Navigation/

import SwiftUI

enum LearnPages: Coordinatable {

    case home
    // ── Add new learn pages here ───────────────────────────────
    // case lessonDetail(String)        // lessonID
    // case quiz(String)                // quizID
    // case quizResult(String, Int)     // quizID, score

    // MARK: - Identifiable
    var id: String {
        switch self {
        case .home: return "learn.home"
        }
    }

    // MARK: - View
    @ViewBuilder
    var body: some View {
        switch self {
        case .home: Text("Learn Home View")  // replace with LearnHomeView()
        }
    }
}