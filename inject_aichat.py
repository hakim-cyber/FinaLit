import os

new_keys = [
    ("dataSharingEnabled", "AI data sharing: Enabled", "AI məlumat paylaşımı: Açıq"),
    ("dataSharingOff", "AI data sharing: Off", "AI məlumat paylaşımı: Bağlı"),
    ("turnOff", "Turn Off", "Bağla"),
    ("review", "Review", "Gözdən keçir"),
    ("tryExample", "Try: \"Why am I overspending this month?\"", "Yoxlayın: \"Niyə bu ay büdcəmi aşıram?\""),
    ("orExample", "Or: \"Which goal should I focus on first?\"", "Və ya: \"Hansı hədəfə öncəlik verməliyəm?\""),
    ("you", "YOU", "SİZ"),
    ("advisor", "ADVISOR", "MƏSLƏHƏTÇİ"),
    ("thinking", "Thinking...", "Düşünür..."),
    ("errorMissingData", "User data is missing. Please log out and log in again.", "İstifadəçi məlumatları yoxdur. Hesabdan çıxıb yenidən daxil olun."),
    ("errorNeedConsent", "Allow AI data sharing before sending messages.", "Mesajlaşmaq üçün AI təhlilinə icazə verin.")
]

# 1. Add to L10n.swift
l10n_path = "/Users/aplle/Desktop/swift learning/FinaLit/FinaLit/Core/Localization/L10n.swift"
with open(l10n_path, "r") as f:
    l10n_content = f.read()

# Make sure we add public enum AiChat if it doesn't exist just in case
if "public enum AiChat {" not in l10n_content:
    enum_def = "\n    public enum AiChat {\n"
    for key, _, _ in new_keys:
        enum_def += f'        public static let {key}: LocalizedStringKey = "aichat.{key}"\n'
    enum_def += "    }\n"
    last_brace_idx = l10n_content.rfind("}")
    l10n_content = l10n_content[:last_brace_idx] + enum_def + l10n_content[last_brace_idx:]
else:
    injection_points = "    public enum AiChat {\n"
    lines_to_inject = ""
    for key, _, _ in new_keys:
        lines_to_inject += f'        public static let {key}: LocalizedStringKey = "aichat.{key}"\n'
    l10n_content = l10n_content.replace(injection_points, injection_points + lines_to_inject)

with open(l10n_path, "w") as f:
    f.write(l10n_content)

# 2. Add to en.lproj/Localizable.strings
en_path = "/Users/aplle/Desktop/swift learning/FinaLit/FinaLit/App/en.lproj/Localizable.strings"
with open(en_path, "a") as f:
    f.write("\n")
    for key, en_str, _ in new_keys:
        f.write(f'"aichat.{key}" = "{en_str}";\n')

# 3. Add to az.lproj/Localizable.strings
az_path = "/Users/aplle/Desktop/swift learning/FinaLit/FinaLit/App/az.lproj/Localizable.strings"
with open(az_path, "a") as f:
    f.write("\n")
    for key, _, az_str in new_keys:
        f.write(f'"aichat.{key}" = "{az_str}";\n')

print("Injected AiChat keys successfully.")

# Script 2: Update Swift Files
ROOT = "/Users/aplle/Desktop/swift learning/FinaLit/FinaLit/Features/AiChat"

replacements = {
    '"AI data sharing: Enabled"': 'String(localized: "aichat.dataSharingEnabled")',
    '"AI data sharing: Off"': 'String(localized: "aichat.dataSharingOff")',
    '"Turn Off"': 'String(localized: "aichat.turnOff")',
    '"Review"': 'String(localized: "aichat.review")',
    '"Try: \\"Why am I overspending this month?\\""': 'String(localized: "aichat.tryExample")',
    '"Or: \\"Which goal should I focus on first?\\""': 'String(localized: "aichat.orExample")',
    '"YOU"': 'String(localized: "aichat.you")',
    '"ADVISOR"': 'String(localized: "aichat.advisor")',
    '"Thinking..."': 'String(localized: "aichat.thinking")',
    '"User data is missing. Please log out and log in again."': 'String(localized: "aichat.errorMissingData")',
    '"Allow AI data sharing before sending messages."': 'String(localized: "aichat.errorNeedConsent")'
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
