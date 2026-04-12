import os

l10n_path = "/Users/aplle/Desktop/swift learning/FinaLit/FinaLit/Core/Localization/L10n.swift"
with open(l10n_path, "r") as f:
    l10n_content = f.read()

injection_points = "    public enum Profile {\n"
lines_to_inject = (
    '        public static let deleteAccount: LocalizedStringKey = "profile.deleteAccount"\n'
)

if 'public static let deleteAccount' not in l10n_content:
    l10n_content = l10n_content.replace(injection_points, injection_points + lines_to_inject)

with open(l10n_path, "w") as f:
    f.write(l10n_content)

en_path = "/Users/aplle/Desktop/swift learning/FinaLit/FinaLit/App/en.lproj/Localizable.strings"
with open(en_path, "a") as f:
    f.write('\n"profile.deleteAccount" = "Delete Account";\n')

az_path = "/Users/aplle/Desktop/swift learning/FinaLit/FinaLit/App/az.lproj/Localizable.strings"
with open(az_path, "a") as f:
    f.write('\n"profile.deleteAccount" = "Hesabı sil";\n')

print("Injected Profile.deleteAccount successfully.")
