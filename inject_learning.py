import os
import re

new_keys = [
    ("reflectionDay", "Reflection Day", "Düşüncə Günü"),
    ("dayPrefix", "Day", "Gün"),
    ("lesson", "Lesson", "Dərs"),
    ("quiz", "Quiz", "Sınaq"),
    ("completeDaysFirst", "Complete all days first", "Əvvəlcə bütün günləri tamamlayın"),
    ("writeWeekReflection", "Write your week reflection", "Həftəlik düşüncənizi yazın"),
    ("correctSuffix", "correct", "düzgün"),
    ("readMore", "Read more ↓", "Daha çox oxu ↓"),
    ("showLess", "Show less ↑", "Daha az göstər ↑"),
    ("correct", "Correct!", "Düzgündür!"),
    ("notQuite", "Not quite", "Tam olaraq yox"),
    ("yourCurriculum", "Your curriculum", "Sizin tədris planınız"),
    ("seeResults", "See Results", "Nəticələrə bax"),
    ("continueBtn", "Continue", "Davam et"),
    ("readThis", "I've read this", "Bunu oxudum"),
    ("readThisCheck", "I've read this ✓", "Bunu oxudum ✓"),
    ("retakeQuiz", "Retake Quiz →", "Sınağı yenidən ver →"),
    ("continueToQuiz", "Continue to Quiz →", "Sınağa davam et →"),
    ("nextQuestion", "Next Question →", "Növbəti sual →"),
    ("seeResultsArrow", "See Results →", "Nəticələrə bax →"),
    ("conceptStuck", "What concept stuck with you most this week?", "Bu həftə yadınızda ən çox hansı anlayış qaldı?"),
    ("doDifferently", "What will you do differently going forward?", "Gələcəkdə fərqli nə edəcəksiniz?"),
    ("changeDecision", "Did you change any financial decision based on what you learned?", "Öyrəndiklərinizə əsasən hansısa maliyyə qərarınızı dəyişdinizmi?"),
    ("correctAnswer", "Correct answer", "Düzgün cavab"),
    ("yourAnswer", "Your answer", "Sizin cavabınız")
]

# 1. Add to L10n.swift
l10n_path = "/Users/aplle/Desktop/swift learning/FinaLit/FinaLit/Core/Localization/L10n.swift"
with open(l10n_path, "r") as f:
    l10n_content = f.read()

# Make sure we add public enum Learning if it doesn't exist
if "public enum Learning" not in l10n_content:
    enum_def = "\n    public enum Learning {\n"
    for key, _, _ in new_keys:
        enum_def += f'        public static let {key}: LocalizedStringKey = "learning.{key}"\n'
    enum_def += "    }\n"
    # insert before the last closing brace
    last_brace_idx = l10n_content.rfind("}")
    l10n_content = l10n_content[:last_brace_idx] + enum_def + l10n_content[last_brace_idx:]
else:
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

print("Injected Learning keys successfully.")

# Script 2: Update Swift Files
ROOT = "/Users/aplle/Desktop/swift learning/FinaLit/FinaLit/Features/FinanceLearning"

replacements = {
    # DayRowCard.swift
    '"Reflection Day"': 'String(localized: "learning.reflectionDay")',
    '"Day \\(day.dayNumber)"': '"\\(String(localized: "learning.dayPrefix")) \\(day.dayNumber)"',
    'label: "Lesson"': 'label: String(localized: "learning.lesson")',
    'label: "Quiz"': 'label: String(localized: "learning.quiz")',
    '"Complete all days first"': 'String(localized: "learning.completeDaysFirst")',
    '"Write your week reflection"': 'String(localized: "learning.writeWeekReflection")',
    '"\\(score)/\\(total) correct"': '"\\(score)/\\(total) \\(String(localized: "learning.correctSuffix"))"',
    
    # DailyTipCard.swift
    '"Read more ↓"': 'String(localized: "learning.readMore")',
    '"Show less ↑"': 'String(localized: "learning.showLess")',
    
    # ExplanationBox.swift
    '"Correct!"': 'String(localized: "learning.correct")',
    '"Not quite"': 'String(localized: "learning.notQuite")',
    
    # LearnHomeView.swift
    '"Your curriculum"': 'String(localized: "learning.yourCurriculum")',
    
    # LearnViewModel.swift (and QuizView, etc.)
    'print("See Results': 'print("See Results', # skip debug prints
    'print("Continue': 'print("Continue',
    'return "See Results"': 'return String(localized: "learning.seeResults")',
    'return "Continue"': 'return String(localized: "learning.continueBtn")',
    'return "I\\\'ve read this"': 'return String(localized: "learning.readThis")',
    # these might be Text("Continue") or something in views, but they are in ViewModel returns based on logs!
    
    # LessonDetailView.swift
    '"I\'ve read this ✓"': 'String(localized: "learning.readThisCheck")',
    '"Retake Quiz →"': 'String(localized: "learning.retakeQuiz")',
    '"Continue to Quiz →"': 'String(localized: "learning.continueToQuiz")',
    
    # QuizView.swift
    '"Next Question →"': 'String(localized: "learning.nextQuestion")',
    '"See Results →"': 'String(localized: "learning.seeResultsArrow")',
    
    # ReflectionView.swift
    '"What concept stuck with you most this week?"': 'String(localized: "learning.conceptStuck")',
    '"What will you do differently going forward?"': 'String(localized: "learning.doDifferently")',
    '"Did you change any financial decision based on what you learned?"': 'String(localized: "learning.changeDecision")',
    
    # WrongAnswerCard.swift
    '"Correct answer"': 'String(localized: "learning.correctAnswer")',
    '"Your answer"': 'String(localized: "learning.yourAnswer")'
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
