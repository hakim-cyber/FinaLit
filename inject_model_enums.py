import os

new_keys = [
    ("personalInfoEditSubtitle", "Keep your identity and lifestyle context up to date.", "Kimliyinizi və həyat tərzi məlumatlarınızı güncəl saxlayın."),
    ("goalsEditSubtitle", "These narrative goals feed AI context and recommendations.", "Bu hekayə formalı məqsədlər süni intellektin təhlilini formalaşdırır."),
    
    ("employmentStudent", "Student", "Tələbə"),
    ("employmentEmployed", "Employed", "İşçi"),
    ("employmentFreelancer", "Freelancer", "Sərbəst işçi"),
    ("employmentBusinessOwner", "Business Owner", "Sahibkar"),
    
    ("employmentStudentDesc", "Currently studying, no regular full-time income", "Hazırda oxuyur, daimi gəliri yoxdur"),
    ("employmentEmployedDesc", "Working full-time or part-time with a fixed salary", "Sabit maaşla tam və ya yarımştat işləyir"),
    ("employmentFreelancerDesc", "Self-employed with variable or project-based income", "Dəyişən və ya layihə əsaslı gəliri olan sərbəst işçi"),
    ("employmentBusinessOwnerDesc", "Owns or runs a business with business income", "Öz biznesi var və ya idarə edir"),
    
    ("riskLow", "Low", "Aşağı"),
    ("riskMedium", "Medium", "Orta"),
    ("riskHigh", "High", "Yüksək"),
    
    ("riskLowDesc", "I prefer safety over growth", "Gəlirdənsə riskin az olmağına üstünlük verirəm"),
    ("riskMediumDesc", "I'm okay with some risk for better returns", "Daha çox gəlir üçün biraz risk almaq olar"),
    ("riskHighDesc", "I chase high returns and accept losses", "Yüksək risklərlə böyük gəlir hədəfləyirəm")
]

# 1. Add to L10n.swift
l10n_path = "/Users/aplle/Desktop/swift learning/FinaLit/FinaLit/Core/Localization/L10n.swift"
with open(l10n_path, "r") as f:
    l10n_content = f.read()

injection_points = "    public enum Profile {\n"
lines_to_inject = ""
for key, _, _ in new_keys:
    if f'let {key}:' not in l10n_content:
        lines_to_inject += f'        public static let {key}: LocalizedStringKey = "profile.{key}"\n'

l10n_content = l10n_content.replace(injection_points, injection_points + lines_to_inject)

with open(l10n_path, "w") as f:
    f.write(l10n_content)

# 2. Add to en.lproj/Localizable.strings
en_path = "/Users/aplle/Desktop/swift learning/FinaLit/FinaLit/App/en.lproj/Localizable.strings"
with open(en_path, "a") as f:
    f.write("\n")
    for key, en_str, _ in new_keys:
        f.write(f'"profile.{key}" = "{en_str}";\n')

# 3. Add to az.lproj/Localizable.strings
az_path = "/Users/aplle/Desktop/swift learning/FinaLit/FinaLit/App/az.lproj/Localizable.strings"
with open(az_path, "a") as f:
    f.write("\n")
    for key, _, az_str in new_keys:
        f.write(f'"profile.{key}" = "{az_str}";\n')

print("Injected Model Domain enum keys successfully.")

# Script 2: Update Swift Files
ROOT = "/Users/aplle/Desktop/swift learning/FinaLit/FinaLit"

replacements = {
    # Subtitles
    '"Keep your identity and lifestyle context up to date."': 'String(localized: "profile.personalInfoEditSubtitle")',
    '"These narrative goals feed AI context and recommendations."': 'String(localized: "profile.goalsEditSubtitle")',
    
    # EmploymentStatus localizations
    'return "Currently studying, no regular full-time income"': 'return String(localized: "profile.employmentStudentDesc")',
    'return "Working full-time or part-time with a fixed salary"': 'return String(localized: "profile.employmentEmployedDesc")',
    'return "Self-employed with variable or project-based income"': 'return String(localized: "profile.employmentFreelancerDesc")',
    'return "Owns or runs a business with business income"': 'return String(localized: "profile.employmentBusinessOwnerDesc")',
    
    # RiskTolerance localizations
    'return "I prefer safety over growth"': 'return String(localized: "profile.riskLowDesc")',
    'return "I\'m okay with some risk for better returns"': 'return String(localized: "profile.riskMediumDesc")',
    'return "I chase high returns and accept losses"': 'return String(localized: "profile.riskHighDesc")',

    # Component references in UI
    'title: status.rawValue': 'title: status.localizedName',
    'title: option.rawValue': 'title: option.localizedName'
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

            # Manually inject `var localizedName: String` into the enums if missing
            if f == "EmploymentStatus.swift" and "localizedName" not in content:
                enum_loc = """
    var localizedName: String {
        switch self {
        case .student: return String(localized: "profile.employmentStudent")
        case .employed: return String(localized: "profile.employmentEmployed")
        case .freelancer: return String(localized: "profile.employmentFreelancer")
        case .businessOwner: return String(localized: "profile.employmentBusinessOwner")
        }
    }
"""
                content = content.replace('var description: String {', enum_loc + '\n    var description: String {')
            
            if f == "RiskTolerance.swift" and "localizedName" not in content:
                enum_loc = """
    var localizedName: String {
        switch self {
        case .low: return String(localized: "profile.riskLow")
        case .medium: return String(localized: "profile.riskMedium")
        case .high: return String(localized: "profile.riskHigh")
        }
    }
"""
                content = content.replace('var description: String {', enum_loc + '\n    var description: String {')
            
            if orig != content:
                with open(path, "w") as p:
                    p.write(content)
                print("Patched:", f)
                count += 1
print(f"Done patching {count} files.")
