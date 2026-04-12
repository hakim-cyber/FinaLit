import os
import re

ROOT = "/Users/aplle/Desktop/swift learning/FinaLit/FinaLit"

replacements = {
    # DashboardView Stats & Quick Actions
    'label: "Expenses"': 'label: String(localized: "main.expense")',
    'label: "Savings"': 'label: String(localized: "main.savings")',
    '"Add Debt" : "Pay Debt"': 'String(localized: "main.addDebt") : String(localized: "main.payDebt")',
    '"Create first debt" : "Add another debt"': 'String(localized: "main.createFirstDebt") : String(localized: "main.addAnotherDebt")',
    '" remaining"': 'String(localized: "main.remaining")',
    '"Add to Goal"': 'String(localized: "main.addToGoal")',
    '"Create first goal" : "Contribute now"': 'String(localized: "main.createFirstGoal") : String(localized: "main.contributeNow")',
    '"Close Month"': 'String(localized: "main.closeMonth")',
    
    # InsightsView & AppSectionHeaders
    'title: "Insights", actionTitle: "See all"': 'title: L10n.Main.insights, actionTitle: L10n.Main.seeAll',
    'title: "Monthly overview"': 'title: L10n.Main.monthlyOverview',
    'label: "Daily Average"': 'label: String(localized: "main.dailyAverage")',
    'label: "Net Balance"': 'label: String(localized: "main.netBalance")',
    'label: "Discretionary"': 'label: String(localized: "main.discretionary")',
    'label: "vs Last Month"': 'label: String(localized: "main.vsLastMonth")',
    'title: "Smart insights"': 'title: L10n.Main.smartInsights',
    'title: "Spending history"': 'title: L10n.Main.spendingHistory',
    'title: "Recent transactions", actionTitle: "All transactions"': 'title: L10n.Main.recentTransactions, actionTitle: L10n.Main.allTransactions',

    # TransactionDetailView
    'DetailRow(label: "Date"': 'DetailRow(label: String(localized: "main.date")',
    'DetailRow(label: "Note"': 'DetailRow(label: String(localized: "main.note")',
    'DetailRow(label: "Recurring"': 'DetailRow(label: String(localized: "main.recurring")',
    'transaction.isRecurring ? "Yes" : "No"': 'transaction.isRecurring ? String(localized: "common.yes") : String(localized: "common.no")',
    
    # SmartInsights (MainViewModel.swift)
    'title:   "You\'re overspending"': 'title:   String(localized: "main.insightOverspending")',
    'message: "Your expenses (\\(formatCurrency(s.monthlyExpenses))) exceed your income (\\(formatCurrency(s.monthlyIncome))) this month."': 'message: "\\(String(localized: "main.expense")) (\\(formatCurrency(s.monthlyExpenses))) \\(String(localized: "main.insightOverspending")) (\\(formatCurrency(s.monthlyIncome))) \\(String(localized: "main.thisMonth"))."',
    'title:   "Low emergency fund"': 'title:   String(localized: "main.insightLowEmergency")',
    'title:   "Low savings rate"': 'title:   String(localized: "main.insightLowSavings")',
    'title:   "High food spending"': 'title:   String(localized: "main.insightHighFood")',
    'title:   "High discretionary spending"': 'title:   String(localized: "main.insightHighDiscretionary")',
    'title:   "Expenses increased"': 'title:   String(localized: "main.insightExpensesIncreased")',
    'title:   "Great savings rate"': 'title:   String(localized: "main.insightGreatSavings")',
    'title:   "Solid emergency fund"': 'title:   String(localized: "main.insightSolidEmergency")',
    'title:   "Spending decreased"': 'title:   String(localized: "main.insightSpendingDecreased")',
    'title:   "No income logged"': 'title:   String(localized: "main.insightNoIncome")',
    'title:   "Start tracking"': 'title:   String(localized: "main.insightStartTracking")',
    'message: "Add your income transactions to get accurate savings rate and insights."': 'message: String(localized: "main.insightNoIncomeDesc")',
    'message: "Add your first transaction to see your financial picture."': 'message: String(localized: "main.insightStartTrackingDesc")',

    # OnboardingExpensesView
    'title: "Monthly expenses"': 'title: String(localized: "onboarding.monthlyExpenses")',
    'subtitle: "Split your recurring and flexible spending."': 'subtitle: String(localized: "onboarding.splitRecurringFlexible")',
    'title: "Fixed expenses"': 'title: String(localized: "onboarding.fixedExpenses")',
    'title: "Variable expenses"': 'title: String(localized: "onboarding.variableExpenses")',
    'primaryTitle: "Continue"': 'primaryTitle: String(localized: "profile.continueAction")',

    # OnboardingIncomeStabilityView
    'title: "Income and stability"': 'title: String(localized: "onboarding.incomeStabilityHeader")',
    'subtitle: "Set your monthly income and tell us how consistent it is."': 'subtitle: String(localized: "onboarding.setMonthlyIncome")',
    'title: "Monthly income"': 'title: String(localized: "onboarding.monthlyIncome")',
    'title: "Stable"': 'title: String(localized: "main.stabilityStable")',
    'title: "Variable"': 'title: String(localized: "onboarding.variable")',

    # FinancialProfileEditView
    'title: "Financial Profile"': 'title: String(localized: "profile.financialProfile")',
    'subtitle: "Update your real-world numbers to keep advice relevant."': 'subtitle: String(localized: "profile.updateRealWorldNumbers")',
    'primaryTitle: "Save Changes"': 'primaryTitle: String(localized: "profile.saveChanges")',
    'localized("Session expired. Please log in again.")': 'String(localized: "profile.sessionExpired")',
    'localized("Monthly income must be greater than 0.")': 'String(localized: "profile.incomeGreaterThanZero")',
    'localized("Debt amount must be greater than 0 when debt is enabled.")': 'String(localized: "profile.debtGreaterThanZero")',
    'localized("Financial profile updated.")': 'String(localized: "profile.financialProfileUpdated")',
    'title: "Current savings"': 'title: String(localized: "main.savings")',
    'title: "No debt"': 'title: String(localized: "profile.noDebt")',
    'title: "I have debt"': 'title: String(localized: "profile.haveDebt")',
    'title: "Debt amount"': 'title: String(localized: "profile.debtAmountField")',
    'title: "Yes"': 'title: String(localized: "common.yes")',
    'title: "Not now"': 'title: String(localized: "aichat.notNow")',
}

def apply_patches():
    count = 0
    for root, _, files in os.walk(ROOT):
        for f in files:
            if f.endswith(".swift"):
                path = os.path.join(root, f)
                with open(path, "r") as p:
                    content = p.read()
                orig = content
                
                # exact matches
                for k, v in replacements.items():
                    content = content.replace(k, v)
                
                if orig != content:
                    with open(path, "w") as p:
                        p.write(content)
                    print("Patched:", f)
                    count += 1
    print(f"Total files patched: {count}")

apply_patches()
