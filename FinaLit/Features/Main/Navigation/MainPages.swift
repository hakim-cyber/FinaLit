//
//  MainPages.swift
//  FinaLit
//
//  Created by aplle on 2/18/26.
//


// MainPages.swift
// Features/Main/Navigation/
// MainPages.swift
// Features/Main/Navigation/

import SwiftUI

enum MainPages: Coordinatable {
    case dashboard
    case addTransaction
    case transactions
    case transactionDetail(String)       // transactionID
    case budget
    case insights
    case goals
    case addGoal
    case goalDetail(String)              // goalID
    case settings

    var id: String {
        switch self {
        case .dashboard:                       return "main.dashboard"
        case .addTransaction:                  return "main.addTransaction"
        case .transactions:                    return "main.transactions"
        case .transactionDetail(let id):       return "main.tx.\(id)"
        case .budget:                          return "main.budget"
        case .insights:                        return "main.insights"
        case .goals:                           return "main.goals"
        case .addGoal:                         return "main.addGoal"
        case .goalDetail(let id):              return "main.goal.\(id)"
        case .settings:                        return "main.settings"
        }
    }

    @ViewBuilder
    var body: some View {
        switch self {
        case .dashboard:                       DashboardView()
        case .addTransaction:                  AddTransactionView()
        case .transactions:                    TransactionsView()
        case .transactionDetail(let id):       TransactionDetailView(transactionID: id)
        case .budget:                          BudgetView()
        case .insights:                        InsightsView()
        case .goals:                           GoalsView()
        case .addGoal:                         AddGoalView()
        case .goalDetail(let id):              GoalDetailView(goalID: id)
        case .settings:                        CoordinatorStack(SettingsPages.home)
        }
    }
}
