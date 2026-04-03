//
//  BudgetView.swift
//  FinaLit
//
//  Created by aplle on 2/20/26.
//


// BudgetView.swift
// Features/Main/Views/

import SwiftUI

struct BudgetView: View {
    @Environment(MainViewModel.self)          private var mainVM
    @Environment(Coordinator<MainPages>.self) private var coordinator
    @State private var editingLimits: [TransactionCategory: String] = [:]
    @State private var isEditing = false

    var body: some View {
        ZStack {
            Color(hex: "0A0A0F").ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    HStack(spacing: 6) {
                        Image(systemName: "calendar")
                            .font(.system(size: 10))
                        Text(mainVM.selectedMonthDisplay.uppercased())
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundStyle(Color(hex: "6B7280"))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(hex: "111118"))
                    .clipShape(Capsule())
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                    // ── Edit toggle ────────────────────────────────────────
                    HStack {
                        Text("Set monthly limits per category.")
                            .font(.system(size: 13))
                            .foregroundStyle(Color(hex: "4B5563"))
                        Spacer()
                        Button(isEditing ? "Save" : "Edit") {
                            if isEditing { saveLimits() }
                            else         { startEditing() }
                            isEditing.toggle()
                        }
                        .font(.system(size: 13))
                        .foregroundStyle(Color(hex: "6366F1"))
                    }
                    .padding(.horizontal, 20)

                    // ── Category rows ──────────────────────────────────────
                    VStack(spacing: 10) {
                        ForEach(TransactionCategory.expenseCategories) { category in
                            BudgetCategoryCard(
                                category:      category,
                                spent:         mainVM.summary?.amount(for: category) ?? 0,
                                limit:         mainVM.budgetLimit(for: category),
                                isEditing:     isEditing,
                                editingText:   Binding(
                                    get: { editingLimits[category] ?? "" },
                                    set: { editingLimits[category] = $0 }
                                )
                            )
                        }
                    }
                    .padding(.horizontal, 20)

                    // ── Total ──────────────────────────────────────────────
                    if let summary = mainVM.summary {
                        TotalBudgetCard(
                            spent: summary.monthlyExpenses,
                            totalLimit: mainVM.budgetLimits.reduce(0) { $0 + $1.limit }
                        )
                        .padding(.horizontal, 20)
                    }

                    Spacer(minLength: 40)
                }
            }
        }
        .navigationTitle("Budget")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func startEditing() {
        for category in TransactionCategory.expenseCategories {
            if let limit = mainVM.budgetLimit(for: category) {
                editingLimits[category] = String(format: "%.0f", limit)
            } else {
                editingLimits[category] = ""
            }
        }
    }

    private func saveLimits() {
        var limits: [BudgetLimit] = []
        for (category, text) in editingLimits {
            if let value = parseMonetaryInput(text), value > 0 {
                limits.append(BudgetLimit(
                    id:       UUID().uuidString,
                    category: category,
                    limit:    value
                ))
            }
        }
        Task { await mainVM.saveBudgetLimits(limits) }
    }
}

struct BudgetCategoryCard: View {
    let category:    TransactionCategory
    let spent:       Double
    let limit:       Double?
    let isEditing:   Bool
    @Binding var editingText: String

    private var usage: Double {
        guard let limit, limit > 0 else { return 0 }
        return min(spent / limit, 1)
    }

    private var isOver: Bool {
        guard let limit else { return false }
        return spent > limit
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(hex: category.color).opacity(0.12))
                        .frame(width: 38, height: 38)
                    Image(systemName: category.icon)
                        .font(.system(size: 15))
                        .foregroundStyle(Color(hex: category.color))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(category.rawValue)
                        .font(.system(size: 15))
                        .foregroundStyle(.white)
                    Text("Spent: \(formatCurrency(spent))")
                        .font(.system(size: 11))
                        .foregroundStyle(Color(hex: "4B5563"))
                }

                Spacer()

                if isEditing {
                    HStack(spacing: 4) {
                        Text(AppRegion.currencySymbol)
                            .font(.system(size: 14))
                            .foregroundStyle(Color(hex: "4B5563"))
                        TextField("Limit", text: $editingText)
                            .font(.system(size: 14))
                            .foregroundStyle(.white)
                            .keyboardType(.decimalPad)
                            .frame(width: 70)
                            .multilineTextAlignment(.trailing)
                    }
                } else if let limit {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(formatCurrency(limit))
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(isOver ? Color(hex: "F87171") : .white)
                        Text("limit")
                            .font(.system(size: 10))
                            .foregroundStyle(Color(hex: "4B5563"))
                    }
                } else {
                    Text("No limit")
                        .font(.system(size: 12))
                        .foregroundStyle(Color(hex: "374151"))
                }
            }

            // Progress bar (only if limit set)
            if limit != nil && !isEditing {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color(hex: "1F2937"))
                            .frame(height: 5)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(isOver ? Color(hex: "F87171") : Color(hex: category.color))
                            .frame(width: geo.size.width * CGFloat(usage), height: 5)
                            .animation(.easeInOut(duration: 0.4), value: usage)
                    }
                }
                .frame(height: 5)
            }
        }
        .padding(14)
        .background(Color(hex: "111118"))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(
                    isOver ? Color(hex: "F87171").opacity(0.3) : Color(hex: "1F2937"),
                    lineWidth: 1
                )
        )
    }
}

struct TotalBudgetCard: View {
    let spent:      Double
    let totalLimit: Double

    private var usage: Double {
        guard totalLimit > 0 else { return 0 }
        return min(spent / totalLimit, 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("TOTAL BUDGET")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Color(hex: "4B5563"))
                Spacer()
                if totalLimit > 0 {
                    Text("\(formatCurrency(spent)) / \(formatCurrency(totalLimit))")
                        .font(.system(size: 13))
                        .foregroundStyle(spent > totalLimit ? Color(hex: "F87171") : .white)
                }
            }
            if totalLimit > 0 {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color(hex: "1F2937"))
                            .frame(height: 6)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(LinearGradient(
                                colors: spent > totalLimit
                                    ? [Color(hex: "F87171"), Color(hex: "F87171")]
                                    : [Color(hex: "6366F1"), Color(hex: "10B981")],
                                startPoint: .leading, endPoint: .trailing
                            ))
                            .frame(width: geo.size.width * CGFloat(usage), height: 6)
                    }
                }
                .frame(height: 6)
            } else {
                Text("Set limits above to track your total budget.")
                    .font(.system(size: 12))
                    .foregroundStyle(Color(hex: "374151"))
            }
        }
        .padding(16)
        .background(Color(hex: "111118"))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(hex: "1F2937"), lineWidth: 1))
    }
}

// ─────────────────────────────────────────────────────────────────────────────

// InsightsView.swift

struct InsightsView: View {
    @Environment(MainViewModel.self) private var mainVM

    var body: some View {
        ZStack {
            Color(hex: "0A0A0F").ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {

                    if let summary = mainVM.summary {
                        // ── Quick stats ────────────────────────────────────
                        VStack(alignment: .leading, spacing: 10) {
                            Text("MONTHLY OVERVIEW")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(Color(hex: "4B5563"))
                                .padding(.horizontal, 20)

                            LazyVGrid(
                                columns: [GridItem(.flexible()), GridItem(.flexible())],
                                spacing: 10
                            ) {
                                InsightStatCard(
                                    label: "Daily Average",
                                    value: formatCurrency(summary.dailyAverage),
                                    icon:  "calendar",
                                    color: "6366F1"
                                )
                                InsightStatCard(
                                    label: "Net Balance",
                                    value: formatSignedCurrency(summary.monthlyNet),
                                    icon:  "equal.circle.fill",
                                    color: summary.monthlyNet >= 0 ? "10B981" : "F87171"
                                )
                                InsightStatCard(
                                    label: "Discretionary",
                                    value: "\(String(format: "%.0f", summary.discretionaryRatio * 100))%",
                                    icon:  "bag.fill",
                                    color: summary.discretionaryRatio > 0.3 ? "FACC15" : "10B981"
                                )
                                if let growth = summary.expenseGrowthRate {
                                    InsightStatCard(
                                        label: "vs Last Month",
                                        value: "\(growth >= 0 ? "+" : "")\(String(format: "%.0f", growth))%",
                                        icon:  growth >= 0 ? "arrow.up.right" : "arrow.down.right",
                                        color: growth > 10 ? "F87171" : growth < -5 ? "10B981" : "6B7280"
                                    )
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }

                    // ── All insights ───────────────────────────────────────
                    VStack(alignment: .leading, spacing: 10) {
                        Text("SMART INSIGHTS")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Color(hex: "4B5563"))
                            .padding(.horizontal, 20)

                        if mainVM.insights.isEmpty {
                            VStack(spacing: 12) {
                                Text("✨")
                                    .font(.system(size: 36))
                                Text("Add transactions to see insights")
                                    .font(.system(size: 15))
                                    .foregroundStyle(Color(hex: "374151"))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(32)
                        } else {
                            ForEach(mainVM.insights) { insight in
                                InsightCard(insight: insight)
                                    .padding(.horizontal, 20)
                            }
                        }
                    }

                    // ── Month history ──────────────────────────────────────
                    if !mainVM.recentSnapshots.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("SPENDING HISTORY")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(Color(hex: "4B5563"))
                                .padding(.horizontal, 20)

                            SpendingHistoryChart(snapshots: mainVM.recentSnapshots)
                                .padding(.horizontal, 20)
                        }
                    }

                    Spacer(minLength: 40)
                }
                .padding(.top, 16)
            }
        }
        .navigationTitle("Insights")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct InsightCard: View {
    let insight: SmartInsight

    private var bgColor: Color {
        switch insight.type {
        case .danger:   return Color(hex: "F87171").opacity(0.06)
        case .warning:  return Color(hex: "FACC15").opacity(0.06)
        case .positive: return Color(hex: "10B981").opacity(0.06)
        case .info:     return Color(hex: "6366F1").opacity(0.06)
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color(hex: insight.color).opacity(0.15))
                    .frame(width: 38, height: 38)
                Image(systemName: insight.icon)
                    .font(.system(size: 15))
                    .foregroundStyle(Color(hex: insight.color))
            }
            VStack(alignment: .leading, spacing: 5) {
                Text(insight.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                Text(insight.message)
                    .font(.system(size: 12))
                    .foregroundStyle(Color(hex: "6B7280"))
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .background(bgColor)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color(hex: insight.color).opacity(0.2), lineWidth: 1)
        )
    }
}

struct InsightStatCard: View {
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
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(label)
                    .font(.system(size: 10))
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

struct SpendingHistoryChart: View {
    let snapshots: [MonthlySnapshot]

    private var maxExpense: Double {
        snapshots.map { $0.totalExpenses }.max() ?? 1
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(snapshots) { snapshot in
                    VStack(spacing: 6) {
                        GeometryReader { geo in
                            VStack(spacing: 0) {
                                Spacer()
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(LinearGradient(
                                        colors: [Color(hex: "6366F1"), Color(hex: "8B5CF6")],
                                        startPoint: .top, endPoint: .bottom
                                    ))
                                    .frame(
                                        height: maxExpense > 0
                                            ? geo.size.height * CGFloat(snapshot.totalExpenses / maxExpense)
                                            : 4
                                    )
                            }
                        }
                        Text(String(snapshot.month.suffix(2)))
                            .font(.system(size: 9))
                            .foregroundStyle(Color(hex: "4B5563"))
                    }
                }
            }
            .frame(height: 80)

            HStack {
                Text(formatCurrency(0))
                Spacer()
                Text(formatCurrency(maxExpense))
            }
            .font(.system(size: 9))
            .foregroundStyle(Color(hex: "374151"))
        }
        .padding(16)
        .background(Color(hex: "111118"))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(hex: "1F2937"), lineWidth: 1))
    }
}
