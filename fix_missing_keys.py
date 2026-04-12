import os

# 1. Add missing keys to L10n.swift
l10n_path = "/Users/aplle/Desktop/swift learning/FinaLit/FinaLit/Core/Localization/L10n.swift"
with open(l10n_path, "r") as f:
    l10n_content = f.read()

# insert into Main enum
injection_points = "    public enum Main {\n"
lines_to_inject = (
    '        public static let deleteGoal2: LocalizedStringKey = "main.deleteGoal2"\n'
    '        public static let delete: LocalizedStringKey = "main.delete"\n'
)

if 'public static let deleteGoal2' not in l10n_content:
    l10n_content = l10n_content.replace(injection_points, injection_points + lines_to_inject)

with open(l10n_path, "w") as f:
    f.write(l10n_content)

# 2. Add to en.lproj/Localizable.strings
en_path = "/Users/aplle/Desktop/swift learning/FinaLit/FinaLit/App/en.lproj/Localizable.strings"
with open(en_path, "a") as f:
    f.write('\n"main.deleteGoal2" = "Delete Goal";\n"main.delete" = "Delete";\n')

# 3. Add to az.lproj/Localizable.strings
az_path = "/Users/aplle/Desktop/swift learning/FinaLit/FinaLit/App/az.lproj/Localizable.strings"
with open(az_path, "a") as f:
    f.write('\n"main.deleteGoal2" = "Hədəfi sil";\n"main.delete" = "Sil";\n')

print("Injected missing keys successfully.")
