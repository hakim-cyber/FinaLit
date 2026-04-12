import os

l10n_path = "/Users/aplle/Desktop/swift learning/FinaLit/FinaLit/Core/Localization/L10n.swift"
with open(l10n_path, "r") as f:
    l10n_content = f.read()

injection_points = "    public enum Main {\n"
lines_to_inject = (
    '        public static let deleteTransaction2: LocalizedStringKey = "main.deleteTransaction2"\n'
    '        public static let deleteTransaction: LocalizedStringKey = "main.deleteTransaction"\n'
)

if 'public static let deleteTransaction2' not in l10n_content:
    l10n_content = l10n_content.replace(injection_points, injection_points + lines_to_inject)

with open(l10n_path, "w") as f:
    f.write(l10n_content)

en_path = "/Users/aplle/Desktop/swift learning/FinaLit/FinaLit/App/en.lproj/Localizable.strings"
with open(en_path, "a") as f:
    f.write('\n"main.deleteTransaction2" = "Delete Transaction";\n"main.deleteTransaction" = "Delete Transaction";\n')

az_path = "/Users/aplle/Desktop/swift learning/FinaLit/FinaLit/App/az.lproj/Localizable.strings"
with open(az_path, "a") as f:
    f.write('\n"main.deleteTransaction2" = "Tranzaksiyanı sil";\n"main.deleteTransaction" = "Tranzaksiyanı sil";\n')

print("Injected missing keys successfully.")
