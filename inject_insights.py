import os
import re

new_keys = [
    ("insightSavingsCover", "Your savings cover less than 1 month of expenses. Aim for at least 3 months.", "Yığımlarınız 1 aylıq xərclərinizi belə qarşılamır. Ən azından 3 ayı hədəfləyin."),
    ("insightSavingPrefix", "You're saving", "Siz gəlirinizin"),
    ("insightSavingSuffix", "of your income. The recommended minimum is 20%.", "hissəsini yığırsınız. Tövsiyə olunan minimum 20%-dir."),
    ("insightFoodPrefix", "Food is", "Qida bu ay xərclərinizin"),
    ("insightFoodSuffix", "of your expenses this month — above the 35% threshold.", "hissəsini təşkil edir — bu 35%-lik limitdən yüksəkdir."),
    ("insightEntertainmentPrefix", "Entertainment and shopping account for", "Əyləncə və alış-veriş gəlirinizin"),
    ("insightEntertainmentSuffix", "of your income.", "hissəsini təşkil edir."),
    ("insightSpendingUpPrefix", "Your spending is up", "Xərcləriniz keçən aya nisbətən"),
    ("insightSpendingUpSuffix", "compared to last month.", "artıb.")
]

# 1. Add to L10n.swift
l10n_path = "/Users/aplle/Desktop/swift learning/FinaLit/FinaLit/Core/Localization/L10n.swift"
with open(l10n_path, "r") as f:
    l10n_content = f.read()

injection_points = "    public enum Main {\n"
lines_to_inject = ""
for key, _, _ in new_keys:
    lines_to_inject += f'        public static let {key}: LocalizedStringKey = "main.{key}"\n'

l10n_content = l10n_content.replace(injection_points, injection_points + lines_to_inject)

with open(l10n_path, "w") as f:
    f.write(l10n_content)

# 2. Add to en.lproj/Localizable.strings
en_path = "/Users/aplle/Desktop/swift learning/FinaLit/FinaLit/App/en.lproj/Localizable.strings"
with open(en_path, "a") as f:
    f.write("\n")
    for key, en_str, _ in new_keys:
        f.write(f'"main.{key}" = "{en_str}";\n')

# 3. Add to az.lproj/Localizable.strings
az_path = "/Users/aplle/Desktop/swift learning/FinaLit/FinaLit/App/az.lproj/Localizable.strings"
with open(az_path, "a") as f:
    f.write("\n")
    for key, _, az_str in new_keys:
        f.write(f'"main.{key}" = "{az_str}";\n')

print("Injected insight keys successfully.")

# Script 2: Update MainViewModel.swift

ROOT = "/Users/aplle/Desktop/swift learning/FinaLit/FinaLit/Features/Main/ViewModels"
replacements = {
    'message: "Your savings cover less than 1 month of expenses. Aim for at least 3 months."': 'message: String(localized: "main.insightSavingsCover")',
    'message: "You\'re saving \\(formatted(s.savingsRate))% of your income. The recommended minimum is 20%."': 'message: "\\(String(localized: "main.insightSavingPrefix")) \\(formatted(s.savingsRate))% \\(String(localized: "main.insightSavingSuffix"))"',
    'message: "Food is \\(formatted(s.percentage(for: .food)))% of your expenses this month — above the 35% threshold."': 'message: "\\(String(localized: "main.insightFoodPrefix")) \\(formatted(s.percentage(for: .food)))% \\(String(localized: "main.insightFoodSuffix"))"',
    'message: "Entertainment and shopping account for \\(formatted(s.discretionaryRatio * 100))% of your income."': 'message: "\\(String(localized: "main.insightEntertainmentPrefix")) \\(formatted(s.discretionaryRatio * 100))% \\(String(localized: "main.insightEntertainmentSuffix"))"',
    'message: "Your spending is up \\(formatted(growth))% compared to last month."': 'message: "\\(String(localized: "main.insightSpendingUpPrefix")) \\(formatted(growth))% \\(String(localized: "main.insightSpendingUpSuffix"))"'
}

for root, _, files in os.walk(ROOT):
    for f in files:
        if f == "MainViewModel.swift":
            path = os.path.join(root, f)
            with open(path, "r") as p:
                content = p.read()
            orig = content
            
            for k, v in replacements.items():
                content = content.replace(k, v)
            
            if orig != content:
                with open(path, "w") as p:
                    p.write(content)
                print("Patched:", f)

print("Done patching.")
