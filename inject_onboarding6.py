import os

new_keys = [
    ("savingsSubtitle", "A quick view of your safety net today.", "Bu günkü təhlükəsizlik yastığınızın qısa xülasəsi."),
    ("emergencyMonths", "%1$d months", "%1$d ay"),
    ("knowledgeSubtitle", "We'll adjust guidance depth and language to match.", "Məsləhətlərin dərinliyini və dilini buna uyğun tənzimləyəcəyik."),
    ("shortTermGoal", "Your short-term goal", "Qısa müddətli məqsədiniz"),
    ("shortTermSubtitle", "Pick one quickly or write your own.", "Tez birini seçin və ya özünüz yazın."),
    ("suggestionEmergencyFund", "Build a %1$@1,000 emergency fund", "%1$@1.000 fövqəladə hal fondu yaratmaq"),
    ("suggestionPayOffCreditCard", "Pay off a credit card", "Kredit kartını ödəmək"),
    ("suggestionSaveLaptop", "Save for a new laptop", "Yeni noutbuk üçün pul yığmaq"),
    ("suggestionSaveTrip", "Save for a trip", "Səyahət üçün pul yığmaq"),
    ("suggestionReduceOverspending", "Reduce monthly overspending", "Aylıq həddindən artıq xərcləməni azaltmaq"),
    ("longTermSubtitle", "This guides strategic recommendations over time.", "Bu, zamanla strateji tövsiyələri yönləndirir."),
    ("pickUpToWeakness", "Pick up to %1$d.", "Maksimum %1$d dənə seçin."),
    ("pickUpToHobbies", "Choose up to %1$d, or add your own.", "Maksimum %1$d dənə seçin və ya özünüz əlavə edin."),
    ("selectedCount", "%1$d/%2$d selected", "%1$d/%2$d seçildi")
]

l10n_path = "/Users/aplle/Desktop/swift learning/FinaLit/FinaLit/Core/Localization/L10n.swift"
with open(l10n_path, "r") as f:
    l10n_content = f.read()

injection_points = "    public enum Onboarding {\n"
lines_to_inject = ""
for key, _, _ in new_keys:
    if f'let {key}:' not in l10n_content:
        lines_to_inject += f'        public static let {key}: LocalizedStringKey = "onboarding.{key}"\n'

l10n_content = l10n_content.replace(injection_points, injection_points + lines_to_inject)

with open(l10n_path, "w") as f:
    f.write(l10n_content)

en_path = "/Users/aplle/Desktop/swift learning/FinaLit/FinaLit/App/en.lproj/Localizable.strings"
with open(en_path, "a") as f:
    f.write("\n")
    for key, en_str, _ in new_keys:
        f.write(f'"onboarding.{key}" = "{en_str}";\n')

az_path = "/Users/aplle/Desktop/swift learning/FinaLit/FinaLit/App/az.lproj/Localizable.strings"
with open(az_path, "a") as f:
    f.write("\n")
    for key, _, az_str in new_keys:
        f.write(f'"onboarding.{key}" = "{az_str}";\n')

print("Injected Onboarding remaining subtitle keys successfully.")

ROOT = "/Users/aplle/Desktop/swift learning/FinaLit/FinaLit/Features/Onboarding"

replacements = {
    '"A quick view of your safety net today."': 'String(localized: "onboarding.savingsSubtitle")',
    'Text("\\(viewModel.emergencyFundMonths) months")': 'Text(String(format: NSLocalizedString("onboarding.emergencyMonths", comment: ""), viewModel.emergencyFundMonths))',
    '"We\'ll adjust guidance depth and language to match."': 'String(localized: "onboarding.knowledgeSubtitle")',
    '"Your short-term goal"': 'String(localized: "onboarding.shortTermGoal")',
    '"Pick one quickly or write your own."': 'String(localized: "onboarding.shortTermSubtitle")',
    '"Build a \\(AppRegion.currencySymbol)1,000 emergency fund"': 'String(format: NSLocalizedString("onboarding.suggestionEmergencyFund", comment: ""), AppRegion.currencySymbol)',
    '"Pay off a credit card"': 'String(localized: "onboarding.suggestionPayOffCreditCard")',
    '"Save for a new laptop"': 'String(localized: "onboarding.suggestionSaveLaptop")',
    '"Save for a trip"': 'String(localized: "onboarding.suggestionSaveTrip")',
    '"Reduce monthly overspending"': 'String(localized: "onboarding.suggestionReduceOverspending")',
    '"This guides strategic recommendations over time."': 'String(localized: "onboarding.longTermSubtitle")',
    '"Pick up to \\(viewModel.maxWeaknessSelections)."': 'String(format: NSLocalizedString("onboarding.pickUpToWeakness", comment: ""), viewModel.maxWeaknessSelections)',
    'Text("\\(viewModel.spendingWeaknesses.count)/\\(viewModel.maxWeaknessSelections) selected")': 'Text(String(format: NSLocalizedString("onboarding.selectedCount", comment: ""), viewModel.spendingWeaknesses.count, viewModel.maxWeaknessSelections))',
    '"Choose up to \\(viewModel.maxHobbySelections), or add your own."': 'String(format: NSLocalizedString("onboarding.pickUpToHobbies", comment: ""), viewModel.maxHobbySelections)',
    'Text("\\(viewModel.normalizedHobbies.count)/\\(viewModel.maxHobbySelections) selected")': 'Text(String(format: NSLocalizedString("onboarding.selectedCount", comment: ""), viewModel.normalizedHobbies.count, viewModel.maxHobbySelections))'
}

count = 0
for root, _, files in os.walk(ROOT):
    for f in files:
        if f.endswith(".swift"):
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
                count += 1
print(f"Done patching {count} files.")
