import os

new_keys = [
    ("insightGreatSavingSuffix", "of your income — above the recommended 20%. Keep it up.", "hissəsini təşkil edir — bu tövsiyə edilən 20%-dən yüksəkdir. Belə davam edin."),
    ("insightOverBudget", "You spent %@ — %@ over your %@ budget.", "Siz %1$@ xərcləmisiniz — təyin edilmiş %3$@ büdcənizdən %2$@ çoxdur."),
    ("insightSolidEmergencyMessage", "Your savings cover more than 3 months of expenses. You're financially stable.", "Yığımlarınız 3 aylıq xərclərinizdən çoxunu qarşılayır. Maliyyə baxımından stabilsiniz."),
    ("insightSpendingDropPrefix", "Your expenses dropped", "Xərcləriniz keçən ayla müqayisədə"),
    ("insightSpendingDropSuffix", "from last month. Good discipline.", "azalıb. Yaxşı nizam-intizam.")
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

print("Injected insight positive keys successfully.")

# Script 2: Update MainViewModel.swift
ROOT = "/Users/aplle/Desktop/swift learning/FinaLit/FinaLit/Features/Main/ViewModels"
replacements = {
    'message: "You\'re saving \\(formatted(s.savingsRate))% of your income — above the recommended 20%. Keep it up."': 'message: "\\(String(localized: "main.insightSavingPrefix")) \\(formatted(s.savingsRate))% \\(String(localized: "main.insightGreatSavingSuffix"))"',
    'message: "You spent \\(formatCurrency(spent)) — \\(formatCurrency(spent - limit.limit)) over your \\(formatCurrency(limit.limit)) budget."': 'message: String(format: NSLocalizedString("main.insightOverBudget", comment: ""), formatCurrency(spent), formatCurrency(spent - limit.limit), formatCurrency(limit.limit))',
    'message: "Your savings cover more than 3 months of expenses. You\'re financially stable."': 'message: String(localized: "main.insightSolidEmergencyMessage")',
    'message: "Your expenses dropped \\(formatted(abs(growth)))% from last month. Good discipline."': 'message: "\\(String(localized: "main.insightSpendingDropPrefix")) \\(formatted(abs(growth)))% \\(String(localized: "main.insightSpendingDropSuffix"))"'
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
