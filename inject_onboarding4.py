import os

new_keys = [
    ("stepTracker", "STEP %1$d OF %2$d", "ADDIM %1$d / %2$d")
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

print("Injected Onboarding.stepTracker keys successfully.")

ROOT = "/Users/aplle/Desktop/swift learning/FinaLit/FinaLit/Features/Onboarding"

replacements = {
    'Text("STEP \\(page.stepNumber) OF \\(OnboardingPages.totalSteps)")': 'Text(String(format: NSLocalizedString("onboarding.stepTracker", comment: ""), page.stepNumber, OnboardingPages.totalSteps))'
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
