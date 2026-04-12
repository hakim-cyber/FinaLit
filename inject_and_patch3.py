import os
import re

new_keys_main = [
    ("activeGoals", "Active goals", "Aktiv hədəflər"),
    ("completed", "Completed", "Tamamlandı"),
    ("deadlinePassed", "Deadline passed", "Son tarix bitib"),
    ("needPrefix", "Need", "Lazımdır"),
    ("perMonth", "/month", "/ay"),
    ("due", "Due", "Son tarix:"),
    ("edit", "Edit", "Redaktə et"),
    ("spentPrefix", "Spent:", "Xərclənib:"),
    ("all", "All", "Hamısı"),
    ("noResults", "No results", "Nəticə yoxdur"),
    ("noTransactions", "No transactions", "Əməliyyat yoxdur")
]

# 1. Add to L10n.swift
l10n_path = "/Users/aplle/Desktop/swift learning/FinaLit/FinaLit/Core/Localization/L10n.swift"
with open(l10n_path, "r") as f:
    l10n_content = f.read()

injection_points = "    public enum Main {\n"
lines_to_inject = ""
for key, _, _ in new_keys_main:
    lines_to_inject += f'        public static let {key}: LocalizedStringKey = "main.{key}"\n'

l10n_content = l10n_content.replace(injection_points, injection_points + lines_to_inject)

with open(l10n_path, "w") as f:
    f.write(l10n_content)

# 2. Add to en.lproj/Localizable.strings
en_path = "/Users/aplle/Desktop/swift learning/FinaLit/FinaLit/App/en.lproj/Localizable.strings"
with open(en_path, "a") as f:
    f.write("\n")
    for key, en_str, _ in new_keys_main:
        f.write(f'"main.{key}" = "{en_str}";\n')

# 3. Add to az.lproj/Localizable.strings
az_path = "/Users/aplle/Desktop/swift learning/FinaLit/FinaLit/App/az.lproj/Localizable.strings"
with open(az_path, "a") as f:
    f.write("\n")
    for key, _, az_str in new_keys_main:
        f.write(f'"main.{key}" = "{az_str}";\n')

print("Injected tertiary keys successfully.")

# Script 2: patch_files3.py functionality

ROOT = "/Users/aplle/Desktop/swift learning/FinaLit/FinaLit"

replacements = {
    # GoalsView
    'AppSectionHeader(title: "Active goals")': 'AppSectionHeader(title: L10n.Main.activeGoals)',
    'AppSectionHeader(title: "Completed")': 'AppSectionHeader(title: L10n.Main.completed)',
    'actionTitle: mainVM.activeGoals.isEmpty ? "New goal" : "See all")': 'actionTitle: mainVM.activeGoals.isEmpty ? L10n.Main.newGoal : L10n.Main.seeAll)',
    
    # GoalCard
    'return "Deadline passed"': 'return String(localized: "main.deadlinePassed")',
    'return "Need \\(formatDisplayCurrency(neededPerMonth))/month"': 'return "\\(String(localized: "main.needPrefix")) \\(formatDisplayCurrency(neededPerMonth))\\(String(localized: "main.perMonth"))"',
    'Text("Due \\(deadline.formatted(date: .abbreviated, time: .omitted))")': 'Text(String(localized: "main.due") + " " + deadline.formatted(date: .abbreviated, time: .omitted))',

    # BudgetView
    'Button(isEditing ? "Save" : "Edit")': 'Button(isEditing ? String(localized: "main.save") : String(localized: "main.edit"))',
    'Text("Spent: \\(formatDisplayCurrency(spent))")': 'Text(String(localized: "main.spentPrefix") + " " + formatDisplayCurrency(spent))',

    # TransactionsView
    'Text("All")': 'Text(String(localized: "main.all"))',
    'Text("No results")': 'Text(String(localized: "main.noResults"))',
    'Text("No transactions")': 'Text(String(localized: "main.noTransactions"))',
}

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
