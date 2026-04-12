import os

new_keys = [
    ("haveDebt", "Do you currently have debt?", "Hazırda borcunuz var mı?"),
    ("whatIsEmploymentStatus", "What's your employment status?", "Məşğulluq statusunuz nədir?"),
    ("hobbyOther", "Other ✏️", "Digər ✏️"),
    ("hobbyFitness", "Fitness 💪", "İdman 💪"),
    ("hobbyFashion", "Fashion 👗", "Moda 👗"),
    ("hobbyCooking", "Cooking 🍳", "Aşpazlıq 🍳"),
    ("hobbyMovies", "Movies 🎬", "Filmlər 🎬"),
    ("hobbyMusic", "Music 🎵", "Musiqi 🎵"),
    ("hobbyTravel", "Travel ✈️", "Səyahət ✈️"),
    ("whatDoYouEnjoy", "What do you enjoy outside money?", "Puldandan əlavə nədən zövq alırsınız?"),
    ("hobbySports", "Sports ⚽", "İdman ⚽"),
    ("hobbyReading", "Reading 📚", "Mütaliə 📚"),
    ("hobbyArt", "Art 🎨", "İncəsənət 🎨"),
    ("hobbyGaming", "Gaming 🎮", "Oyunlar 🎮"),
    ("hobbyPhotography", "Photography 📷", "Fotoqrafiya 📷"),
    ("rateKnowledge", "How would you rate your financial knowledge?", "Maliyyə biliyinizi necə qiymətləndirirsiniz?"),
    ("knowledgeBeginner", "Beginner", "Başlanğıc"),
    ("knowledgeBeginnerDesc", "Simple, practical next steps", "Sadə və praktik addımlar"),
    ("knowledgeIntermediate", "Intermediate", "Orta"),
    ("knowledgeIntermediateDesc", "Balanced insights with more detail", "Daha ətraflı və balanslı təhlil"),
    ("knowledgeAdvanced", "Advanced", "İrəli"),
    ("knowledgeAdvancedDesc", "Higher detail and analytical trade-offs", "Daha detallı və analitik yanaşma"),
    ("finishSetup", "Finish Setup", "Quraşdırmanı Bitir"),
    ("longTermGoal", "Your long-term goal", "Uzunmüddətli məqsədiniz"),
    ("goalRetireEarly", "Retire early", "Erkən təqaüd"),
    ("goalFinancialIndependence", "Reach financial independence", "Maliyyə müstəqilliyinə çatmaq"),
    ("goalStartBusiness", "Start a business", "Biznesə başlamaq"),
    ("goalPortfolio", "Build a 6-figure portfolio", "Böyük portfel yaratmaq"),
    ("goalBuyHome", "Buy a home", "Ev almaq"),
    ("tellUsAboutYou", "Tell us about you", "Özünüz haqqında məlumat verin"),
    ("countryGermany", "Germany", "Almaniya"),
    ("countryAzerbaijan", "Azerbaijan", "Azərbaycan"),
    ("countryUS", "United States", "Amerika Birləşmiş Ştatları"),
    ("countryUK", "United Kingdom", "Birləşmiş Krallıq"),
    ("countryCanada", "Canada", "Kanada"),
    ("countryTurkey", "Turkey", "Türkiyə"),
    ("riskInterest", "Risk and investing interest", "Risk və İnvestisiya marağı"),
    ("onboardingRiskLow", "Low", "Aşağı"),
    ("onboardingRiskMedium", "Medium", "Orta"),
    ("onboardingRiskHigh", "High", "Yüksək"),
    ("onboardingRiskLowDesc", "Safety first, steady progress", "Təhlükəsizlik ön planda, sabit irəliləyiş"),
    ("onboardingRiskMediumDesc", "Balanced risk and growth", "Balanslaşdırılmış risk və böyümə"),
    ("onboardingRiskHighDesc", "Higher volatility for higher potential", "Yüksək potensial üçün yüksək dəyişkənlik"),
    ("savingsEmergency", "Savings and emergency buffer", "Yığım və fövqəladə hal fondu"),
    ("overspendMost", "Where do you overspend most?", "Ən çox hara xərcləyirsiniz?"),
    ("creditCard", "Credit Card", "Kredit Kartı")
]

# 1. Add to L10n.swift
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

# 2. Add to en.lproj/Localizable.strings
en_path = "/Users/aplle/Desktop/swift learning/FinaLit/FinaLit/App/en.lproj/Localizable.strings"
with open(en_path, "a") as f:
    f.write("\n")
    for key, en_str, _ in new_keys:
        f.write(f'"onboarding.{key}" = "{en_str}";\n')

# 3. Add to az.lproj/Localizable.strings
az_path = "/Users/aplle/Desktop/swift learning/FinaLit/FinaLit/App/az.lproj/Localizable.strings"
with open(az_path, "a") as f:
    f.write("\n")
    for key, _, az_str in new_keys:
        f.write(f'"onboarding.{key}" = "{az_str}";\n')

print("Injected Onboarding keys successfully.")

# Script 2: Update Swift Files
ROOT = "/Users/aplle/Desktop/swift learning/FinaLit/FinaLit/Features/Onboarding"

replacements = {
    '"Do you currently have debt?"': 'String(localized: "onboarding.haveDebt")',
    '"What\\\'s your employment status?"': 'String(localized: "onboarding.whatIsEmploymentStatus")',
    '"Other ✏️"': 'String(localized: "onboarding.hobbyOther")',
    '"Fitness 💪"': 'String(localized: "onboarding.hobbyFitness")',
    '"Fashion 👗"': 'String(localized: "onboarding.hobbyFashion")',
    '"Cooking 🍳"': 'String(localized: "onboarding.hobbyCooking")',
    '"Movies 🎬"': 'String(localized: "onboarding.hobbyMovies")',
    '"Music 🎵"': 'String(localized: "onboarding.hobbyMusic")',
    '"Travel ✈️"': 'String(localized: "onboarding.hobbyTravel")',
    '"What do you enjoy outside money?"': 'String(localized: "onboarding.whatDoYouEnjoy")',
    '"Sports ⚽"': 'String(localized: "onboarding.hobbySports")',
    '"Reading 📚"': 'String(localized: "onboarding.hobbyReading")',
    '"Art 🎨"': 'String(localized: "onboarding.hobbyArt")',
    '"Gaming 🎮"': 'String(localized: "onboarding.hobbyGaming")',
    '"Photography 📷"': 'String(localized: "onboarding.hobbyPhotography")',
    '"How would you rate your financial knowledge?"': 'String(localized: "onboarding.rateKnowledge")',
    '"Beginner"': 'String(localized: "onboarding.knowledgeBeginner")',
    '"Simple, practical next steps"': 'String(localized: "onboarding.knowledgeBeginnerDesc")',
    '"Intermediate"': 'String(localized: "onboarding.knowledgeIntermediate")',
    '"Balanced insights with more detail"': 'String(localized: "onboarding.knowledgeIntermediateDesc")',
    '"Advanced"': 'String(localized: "onboarding.knowledgeAdvanced")',
    '"Higher detail and analytical trade-offs"': 'String(localized: "onboarding.knowledgeAdvancedDesc")',
    '"Finish Setup"': 'String(localized: "onboarding.finishSetup")',
    '"Your long-term goal"': 'String(localized: "onboarding.longTermGoal")',
    '"Retire early"': 'String(localized: "onboarding.goalRetireEarly")',
    '"Reach financial independence"': 'String(localized: "onboarding.goalFinancialIndependence")',
    '"Start a business"': 'String(localized: "onboarding.goalStartBusiness")',
    '"Build a 6-figure portfolio"': 'String(localized: "onboarding.goalPortfolio")',
    '"Buy a home"': 'String(localized: "onboarding.goalBuyHome")',
    '"Tell us about you"': 'String(localized: "onboarding.tellUsAboutYou")',
    '"Germany"': 'String(localized: "onboarding.countryGermany")',
    '"Azerbaijan"': 'String(localized: "onboarding.countryAzerbaijan")',
    '"United States"': 'String(localized: "onboarding.countryUS")',
    '"United Kingdom"': 'String(localized: "onboarding.countryUK")',
    '"Canada"': 'String(localized: "onboarding.countryCanada")',
    '"Turkey"': 'String(localized: "onboarding.countryTurkey")',
    '"Risk and investing interest"': 'String(localized: "onboarding.riskInterest")',
    '"Low"': 'String(localized: "onboarding.onboardingRiskLow")',
    '"Medium"': 'String(localized: "onboarding.onboardingRiskMedium")',
    '"High"': 'String(localized: "onboarding.onboardingRiskHigh")',
    '"Safety first, steady progress"': 'String(localized: "onboarding.onboardingRiskLowDesc")',
    '"Balanced risk and growth"': 'String(localized: "onboarding.onboardingRiskMediumDesc")',
    '"Higher volatility for higher potential"': 'String(localized: "onboarding.onboardingRiskHighDesc")',
    '"Savings and emergency buffer"': 'String(localized: "onboarding.savingsEmergency")',
    '"Where do you overspend most?"': 'String(localized: "onboarding.overspendMost")',
    '"Credit Card"': 'String(localized: "onboarding.creditCard")'
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
