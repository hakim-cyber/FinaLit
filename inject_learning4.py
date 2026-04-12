import os

new_keys = [
    ("weekHistory", "Week history", "Həftə tarixçəsi"),
    ("yourReflections", "Your reflections", "Düşüncələriniz"),
    ("dayCompleteNextDayUnlocked", "Day Complete — Next day unlocked", "Gün tamamlandı — Növbəti gün kiliddən çıxdı"),
    ("keepStudying", "Keep studying — You'll get it!", "Öyrənməyə davam edin — Alınacaq!"),
    ("lessonsRead", "Lessons Read", "Oxunmuş Dərslər"),
    ("quizzesDone", "Quizzes Done", "Həll Edilmiş Sınaqlar"),
    ("dayStreak", "Day Streak", "Ardıcıl Günlər"),
    ("avgQuizScore", "Avg Quiz Score", "Ortalama Sınaq Nəticəsi")
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

print("Injected Learning Stats keys part 4 successfully.")

# Script 2: Update Swift Files
ROOT = "/Users/aplle/Desktop/swift learning/FinaLit/FinaLit"

replacements = {
    # Headers
    'AppSectionHeader(title: "Week history")': 'AppSectionHeader(title: L10n.Learning.weekHistory)',
    'AppSectionHeader(title: "Your reflections")': 'AppSectionHeader(title: L10n.Learning.yourReflections)',
    
    # ScoreCard
    '"\\(percentage)% correct"': '"\\(percentage)% \\(String(localized: "learning.correctSuffix"))"',
    '"Day Complete — Next day unlocked" : "Keep studying — You\'ll get it!"': 'String(localized: "learning.dayCompleteNextDayUnlocked") : String(localized: "learning.keepStudying")',
    
    # ProgressStatCard
    'label: "Lessons Read"': 'label: String(localized: "learning.lessonsRead")',
    'label: "Quizzes Done"': 'label: String(localized: "learning.quizzesDone")',
    'label: "Day Streak"': 'label: String(localized: "learning.dayStreak")',
    'label: "Avg Quiz Score"': 'label: String(localized: "learning.avgQuizScore")'
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
