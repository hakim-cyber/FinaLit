//
//  MainPages.swift
//  FinaLit
//
//  Created by aplle on 2/18/26.
//


// MainPages.swift
// Features/Main/Navigation/

import SwiftUI

enum MainPages: Coordinatable {

    case dashboard
    // ── Add new main pages here ────────────────────────────────
    // case addExpense
    // case expenseDetail(String)   // pass IDs as associated values
    // case insights
    // case profile

    // MARK: - Identifiable
    var id: String {
        switch self {
        case .dashboard: return "main.dashboard"
        }
    }

    // MARK: - View
    @ViewBuilder
    var body: some View {
        switch self {
        case .dashboard: Text("Dashboard View")  // replace with DashboardView()
        }
    }
}