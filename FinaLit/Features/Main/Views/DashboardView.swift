//
//  DashboardView.swift
//  FinaLit
//
//  Created by aplle on 2/20/26.
//


// DashboardView.swift
// Features/Main/Views/

import SwiftUI

struct DashboardView: View {
    @Environment(MainViewModel.self)           private var mainVM
    @Environment(UserSession.self)             private var session
    @Environment(Coordinator<MainPages>.self)  private var coordinator

    var body: some View {
        ZStack {
            Color(hex: "0A0A0F").ignoresSafeArea()

            if mainVM.isLoadingHome {
                MainLoadingView()
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {

                        headerSection
                        balanceHeroCard
                        statsRow
                        insightsStrip
                        categoryBreakdown
                        goalsPreview
                        recentTransactions

                        Spacer(minLength: 100)
                    }
                    .padding(.top, 16)
                }
            }

            // ── FAB: Add Transaction ───────────────────────────────────────
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button {
                       
                        coordinator.push(.addTransaction, type: .sheet)

                        
                    } label: {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(
                                    colors: [Color(hex: "6366F1"), Color(hex: "4F46E5")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .frame(width: 56, height: 56)
                                .shadow(color: Color(hex: "6366F1").opacity(0.4), radius: 12, y: 4)
                            Image(systemName: "plus")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                    }
                    .padding(.trailing, 24)
                    .padding(.bottom, 16)
                }
            }
        }
        .navigationBarHidden(true)
        .task { await mainVM.loadHome() }
        .alert("Error", isPresented: .constant(mainVM.errorMessage != nil)) {
            Button("OK") { mainVM.clearError() }
        } message: {
            Text(mainVM.errorMessage ?? "")
        }
    }

    // MARK: - Header
    private var headerSection: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(greeting)
                    .font(.system(size: 14, design: .monospaced))
                    .foregroundStyle(Color(hex: "4B5563"))
                Text(session.user?.name.components(separatedBy: " ").first ?? "")
                    .font(.system(size: 28, weight: .light, design: .serif))
                    .foregroundStyle(.white)
            }
            Spacer()
            // Month navigator
            MonthNavigator()
        }
        .padding(.horizontal, 20)
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12:  return "good morning"
        case 12..<17: return "good afternoon"
        default:      return "good evening"
        }
    }

    // MARK: - Balance Hero Card
    private var balanceHeroCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 6) {
                Text("CURRENT BALANCE")
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Color(hex: "4B5563"))

                if let summary = mainVM.summary {
                    Text("€\(formatAmount(summary.currentBalance))")
                        .font(.system(size: 42, weight: .light, design: .serif))
                        .foregroundStyle(summary.currentBalance >= 0 ? .white : Color(hex: "F87171"))
                } else {
                    Text("€ —")
                        .font(.system(size: 42, weight: .light, design: .serif))
                        .foregroundStyle(Color(hex: "374151"))
                }
            }

            // Stability badge
            if let summary = mainVM.summary {
                HStack(spacing: 6) {
                    Image(systemName: summary.financialStability.icon)
                        .font(.system(size: 11))
                    Text(summary.financialStability.rawValue)
                        .font(.system(size: 11, design: .monospaced))
                }
                .foregroundStyle(Color(hex: summary.financialStability.color))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(hex: summary.financialStability.color).opacity(0.12))
                .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(22)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(hex: "111118"))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color(hex: "1F2937"), lineWidth: 1)
                )
        )
        .padding(.horizontal, 20)
    }

    // MARK: - Stats Row (3 cards)
    private var statsRow: some View {
        HStack(spacing: 10) {
            StatMiniCard(
                label:  "Income",
                value:  mainVM.summary.map { "€\(formatAmount($0.monthlyIncome))" } ?? "—",
                icon:   "arrow.up.circle.fill",
                color:  "10B981"
            )
            StatMiniCard(
                label:  "Expenses",
                value:  mainVM.summary.map { "€\(formatAmount($0.monthlyExpenses))" } ?? "—",
                icon:   "arrow.down.circle.fill",
                color:  "F87171"
            )
            StatMiniCard(
                label:  "Savings",
                value:  mainVM.summary.map { "\(formatAmount($0.savingsRate))%" } ?? "—",
                icon:   "chart.line.uptrend.xyaxis",
                color:  mainVM.summary.map { $0.savingsRate >= 20 ? "10B981" : "FACC15" } ?? "6B7280"
            )
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Insights Strip
    private var insightsStrip: some View {
        Group {
            if !mainVM.insights.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("INSIGHTS")
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                            .foregroundStyle(Color(hex: "4B5563"))
                        Spacer()
                        Button("See all →") {
                            coordinator.push(.insights)
                        }
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(Color(hex: "6366F1"))
                    }
                    .padding(.horizontal, 20)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(mainVM.insights.prefix(4)) { insight in
                                InsightChip(insight: insight)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
            }
        }
    }

    // MARK: - Category Breakdown
    private var categoryBreakdown: some View {
        Group {
            if let summary = mainVM.summary, !summary.byCategory.isEmpty {
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Text("THIS MONTH")
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                            .foregroundStyle(Color(hex: "4B5563"))
                        Spacer()
                        Button("Budget →") {
                            coordinator.push(.budget)
                        }
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(Color(hex: "6366F1"))
                    }
                    .padding(.horizontal, 20)

                    VStack(spacing: 8) {
                        ForEach(summary.topCategories, id: \.0) { category, amount in
                            CategoryRow(
                                category:   category,
                                amount:     amount,
                                total:      summary.monthlyExpenses,
                                limit:      mainVM.budgetLimit(for: category)
                            )
                        }
                    }
                    .padding(.horizontal, 20)

                    if summary.byCategory.count > 3 {
                        Button("View all categories →") {
                            coordinator.push(.budget)
                        }
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(Color(hex: "4B5563"))
                        .padding(.horizontal, 20)
                    }
                }
            }
        }
    }

    // MARK: - Goals Preview
    private var goalsPreview: some View {
        Group {
            if !mainVM.activeGoals.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("GOALS")
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                            .foregroundStyle(Color(hex: "4B5563"))
                        Spacer()
                        Button("See all →") {
                            coordinator.push(.goals)
                        }
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(Color(hex: "6366F1"))
                    }
                    .padding(.horizontal, 20)

                    ForEach(mainVM.activeGoals.prefix(2)) { goal in
                        GoalPreviewCard(goal: goal)
                            .padding(.horizontal, 20)
                            .onTapGesture {
                                coordinator.push(.goalDetail(goal.id ?? ""))
                            }
                    }
                }
            }
        }
    }

    // MARK: - Recent Transactions
    private var recentTransactions: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("RECENT")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Color(hex: "4B5563"))
                Spacer()
                Button("All transactions →") {
                    coordinator.push(.transactions)
                }
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(Color(hex: "6366F1"))
            }
            .padding(.horizontal, 20)

            if mainVM.currentMonthTransactions.isEmpty {
                EmptyTransactionsCard()
                    .padding(.horizontal, 20)
            } else {
                VStack(spacing: 1) {
                    ForEach(mainVM.currentMonthTransactions.prefix(5)) { tx in
                        TransactionRow(transaction: tx)
                            .onTapGesture {
                                coordinator.push(.transactionDetail(tx.id ?? ""))
                            }
                    }
                }
                .background(Color(hex: "111118"))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .padding(.horizontal, 20)
            }
        }
    }
}

// MARK: - Month Navigator
struct MonthNavigator: View {
    @Environment(MainViewModel.self) private var mainVM

    var body: some View {
        HStack(spacing: 12) {
            Button {
                mainVM.goToPreviousMonth()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color(hex: "6B7280"))
            }

            Text(mainVM.selectedMonthDisplay)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(Color(hex: "9CA3AF"))
                .frame(minWidth: 80)

            Button {
                mainVM.goToNextMonth()
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(mainVM.isCurrentMonth ? Color(hex: "1F2937") : Color(hex: "6B7280"))
            }
            .disabled(mainVM.isCurrentMonth)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Color(hex: "111118"))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Stat Mini Card
struct StatMiniCard: View {
    let label: String
    let value: String
    let icon:  String
    let color: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(Color(hex: color))
                .font(.system(size: 16))
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 17, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(label)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(Color(hex: "4B5563"))
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(hex: "111118"))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(hex: "1F2937"), lineWidth: 1))
    }
}

// MARK: - Insight Chip
struct InsightChip: View {
    let insight: SmartInsight

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: insight.icon)
                .font(.system(size: 13))
                .foregroundStyle(Color(hex: insight.color))
            VStack(alignment: .leading, spacing: 2) {
                Text(insight.title)
                    .font(.system(size: 12, weight: .medium, design: .serif))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text(insight.message)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(Color(hex: "6B7280"))
                    .lineLimit(2)
            }
        }
        .padding(12)
        .frame(width: 220, alignment: .leading)
        .background(Color(hex: "111118"))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(hex: insight.color).opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Category Row
struct CategoryRow: View {
    let category: TransactionCategory
    let amount:   Double
    let total:    Double
    let limit:    Double?

    private var percentage: Double {
        guard total > 0 else { return 0 }
        return (amount / total) * 100
    }

    private var isOverBudget: Bool {
        guard let limit else { return false }
        return amount > limit
    }

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: category.icon)
                        .font(.system(size: 13))
                        .foregroundStyle(Color(hex: category.color))
                        .frame(width: 20)
                    Text(category.rawValue)
                        .font(.system(size: 14, design: .serif))
                        .foregroundStyle(.white)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 1) {
                    Text("€\(formatAmount(amount))")
                        .font(.system(size: 14, weight: .semibold, design: .monospaced))
                        .foregroundStyle(isOverBudget ? Color(hex: "F87171") : .white)
                    if let limit {
                        Text("of €\(formatAmount(limit))")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(Color(hex: "4B5563"))
                    } else {
                        Text("\(String(format: "%.0f", percentage))%")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(Color(hex: "4B5563"))
                    }
                }
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color(hex: "1F2937"))
                        .frame(height: 3)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(isOverBudget ? Color(hex: "F87171") : Color(hex: category.color))
                        .frame(
                            width: limit != nil
                                ? min(geo.size.width * CGFloat(amount / limit!), geo.size.width)
                                : geo.size.width * CGFloat(percentage / 100),
                            height: 3
                        )
                }
            }
            .frame(height: 3)
        }
        .padding(14)
        .background(Color(hex: "111118"))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    isOverBudget ? Color(hex: "F87171").opacity(0.3) : Color(hex: "1F2937"),
                    lineWidth: 1
                )
        )
    }
}

// MARK: - Goal Preview Card
struct GoalPreviewCard: View {
    let goal: FinancialGoal

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(goal.title)
                    .font(.system(size: 15, design: .serif))
                    .foregroundStyle(.white)
                Spacer()
                Text("\(String(format: "%.0f", goal.progressPercentage))%")
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Color(hex: "6366F1"))
            }
            HStack {
                Text("€\(formatAmount(goal.currentAmount))")
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundStyle(Color(hex: "9CA3AF"))
                Text("of €\(formatAmount(goal.targetAmount))")
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundStyle(Color(hex: "4B5563"))
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(hex: "1F2937"))
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(LinearGradient(
                            colors: [Color(hex: "6366F1"), Color(hex: "10B981")],
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                        .frame(
                            width: geo.size.width * CGFloat(goal.progressPercentage / 100),
                            height: 6
                        )
                }
            }
            .frame(height: 6)
        }
        .padding(16)
        .background(Color(hex: "111118"))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(hex: "1F2937"), lineWidth: 1))
    }
}

// MARK: - Transaction Row
struct TransactionRow: View {
    let transaction: Transaction

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(hex: transaction.category.color).opacity(0.12))
                    .frame(width: 38, height: 38)
                Image(systemName: transaction.category.icon)
                    .font(.system(size: 14))
                    .foregroundStyle(Color(hex: transaction.category.color))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.note.isEmpty ? transaction.category.rawValue : transaction.note)
                    .font(.system(size: 14, design: .serif))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text(transaction.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(Color(hex: "4B5563"))
            }
            Spacer()
            Text("\(transaction.isIncome ? "+" : "-")€\(formatAmount(transaction.amount))")
                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                .foregroundStyle(transaction.isIncome ? Color(hex: "10B981") : .white)
        }
        .padding(12)
    }
}

// MARK: - Empty State
struct EmptyTransactionsCard: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("💸")
                .font(.system(size: 36))
            Text("No transactions yet")
                .font(.system(size: 16, design: .serif))
                .foregroundStyle(.white)
            Text("Tap + to add your first transaction")
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(Color(hex: "4B5563"))
        }
        .frame(maxWidth: .infinity)
        .padding(32)
        .background(Color(hex: "111118"))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct MainLoadingView: View {
    var body: some View {
        ZStack {
            Color(hex: "0A0A0F").ignoresSafeArea()
            ProgressView()
                .tint(Color(hex: "6366F1"))
                .scaleEffect(1.3)
        }
    }
}

// MARK: - Format helper (shared across Main views)
func formatAmount(_ value: Double) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.maximumFractionDigits = value.truncatingRemainder(dividingBy: 1) == 0 ? 0 : 2
    formatter.minimumFractionDigits = 0
    return formatter.string(from: NSNumber(value: value)) ?? String(format: "%.2f", value)
}
