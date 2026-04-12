import os

new_keys = [
    ("weekPrefixUpper", "WEEK", "HƏFTƏ"),
    ("lessons", "Lessons", "Dərslər"),
    ("quizzes", "Quizzes", "Sınaqlar"),
    ("avgScore", "Avg Score", "Ortalama nəticə"),
    ("level", "Level", "Səviyyə")
]

# 1. Add to L10n.swift
l10n_path = "/Users/aplle/Desktop/swift learning/FinaLit/FinaLit/Core/Localization/L10n.swift"
with open(l10n_path, "r") as f:
    l10n_content = f.read()

injection_points = "    public enum Learning {\n"
lines_to_inject = ""
for key, _, _ in new_keys:
    lines_to_inject += f'        public static let {key}: LocalizedStringKey = "learning.{key}"\n'

l10n_content = l10n_content.replace(injection_points, injection_points + lines_to_inject)

with open(l10n_path, "w") as f:
    f.write(l10n_content)

# 2. Add to en.lproj/Localizable.strings
en_path = "/Users/aplle/Desktop/swift learning/FinaLit/FinaLit/App/en.lproj/Localizable.strings"
with open(en_path, "a") as f:
    f.write("\n")
    for key, en_str, _ in new_keys:
        f.write(f'"learning.{key}" = "{en_str}";\n')

# 3. Add to az.lproj/Localizable.strings
az_path = "/Users/aplle/Desktop/swift learning/FinaLit/FinaLit/App/az.lproj/Localizable.strings"
with open(az_path, "a") as f:
    f.write("\n")
    for key, _, az_str in new_keys:
        f.write(f'"learning.{key}" = "{az_str}";\n')

print("Injected Learning Stats keys successfully.")

# Script 2: Update Swift Files
ROOT = "/Users/aplle/Desktop/swift learning/FinaLit/FinaLit/Features/FinanceLearning"

replacements = {
    # LearnHomeView fix
    'String(localized: "learning.yourCurriculum")': 'L10n.Learning.yourCurriculum',
    
    # LearningProgressView
    '"WEEK \\(localizedWeek.weekNumber)"': '"\\(String(localized: "learning.weekPrefixUpper")) \\(localizedWeek.weekNumber)"',
    
    # StatsStrip
    'label: "Lessons"': 'label: String(localized: "learning.lessons")',
    'label: "Quizzes"': 'label: String(localized: "learning.quizzes")',
    'label: "Avg Score"': 'label: String(localized: "learning.avgScore")',
    'label: "Level"': 'label: String(localized: "learning.level")'
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
