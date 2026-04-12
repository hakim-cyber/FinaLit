import os
import re

ROOT = "/Users/aplle/Desktop/swift learning/FinaLit/FinaLit/Features/Main"

replacements = {
    # .rawValue replacments in UI
    'Text(category.rawValue)': 'Text(category.localizedName)',
    'Text(summary.financialStability.rawValue)': 'Text(summary.financialStability.localizedName)',
    'title: summary.financialStability.rawValue,': 'title: String(localized: "main.stabilityStable"),', # will fix exactly with generic approach below
    'Text(transaction.note.isEmpty ? transaction.category.rawValue : transaction.note)': 'Text(transaction.note.isEmpty ? transaction.category.localizedName : LocalizedStringKey(transaction.note))',
    'Text(type == .expense ? "Expense" : "Income")': 'Text(type == .expense ? L10n.Main.expense : L10n.Main.income)',
    'Text(transaction.type == .income ? "Income" : "Expense")': 'Text(transaction.type == .income ? L10n.Main.income : L10n.Main.expense)',
    'prompt: "Search transactions"': 'prompt: Text(L10n.Main.searchTransactions)',
    'filterMenuLabel(title: "Expense"': 'filterMenuLabel(title: String(localized: "main.expense")',
    'filterMenuLabel(title: "Income"': 'filterMenuLabel(title: String(localized: "main.income")',
    'AppSectionHeader(title: "Actions")': 'AppSectionHeader(title: L10n.Main.actions)',
    'AppSectionHeader(title: "This month", actionTitle: "Budget")': 'AppSectionHeader(title: L10n.Main.thisMonth, actionTitle: L10n.Main.budget)',
    'AppSectionHeader(title: "Overview")': 'AppSectionHeader(title: L10n.Main.overview)',
    'label: "Income"': 'label: String(localized: "main.income")',
    'DetailRow(label: "Category", value: transaction.category.rawValue)': 'DetailRow(label: String(localized: "main.category"), value: String(localized: LocalizedStringResource(stringLiteral: "main.category\(transaction.category.rawValue)"))) '
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
                
                if '"\\(limit.category.rawValue) budget exceeded"' in content:
                    content = content.replace('"\\(limit.category.rawValue) budget exceeded"', 'String(localized: .init(stringLiteral: "main.category\\(limit.category.rawValue)")) + " " + String(localized: "budget exceeded")')
                    
                if 'title: summary.financialStability.rawValue,' in content:
                    content = content.replace('title: summary.financialStability.rawValue,', 'title: String(localized: .init(stringLiteral: "main.stability\\(summary.financialStability.rawValue)")),')

                    
                if orig != content:
                    with open(path, "w") as p:
                        p.write(content)
                    count += 1
    print(f"Patched {count} files")

apply_patches()
