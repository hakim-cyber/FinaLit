import os

new_keys = [
    ("categoryFood", "Food", "Qida"),
    ("categoryTransport", "Transport", "Nəqliyyat"),
    ("categoryRent", "Rent", "Kirayə"),
    ("categoryEducation", "Education", "Təhsil"),
    ("categoryHealth", "Health", "Sağlamlıq"),
    ("categoryEntertainment", "Entertainment", "Əyləncə"),
    ("categoryShopping", "Shopping", "Alış-veriş"),
    ("categoryOther", "Other", "Digər"),
    ("categorySalary", "Salary", "Maaş"),
    ("categoryFreelance", "Freelance", "Frilans"),
    ("categoryInvestment", "Investment Return", "İnvestisiya Gəliri"),
    ("categoryGift", "Gift", "Hədiyyə"),
    ("categoryOtherIncome", "Other Income", "Digər Gəlir"),
    ("categoryTech", "Tech", "Texnologiya"),
    ("categoryClothes", "Clothes", "Geyim"),
    ("categoryTravel", "Travel", "Səyahət"),
    ("stabilityStable", "Stable", "Sabit"),
    ("stabilityModerate", "Moderate", "Orta"),
    ("stabilityRisky", "Risky", "Riskli"),
    ("searchTransactions", "Search transactions", "Əməliyyatları axtar"),
    ("actions", "Actions", "Əmliyyatlar"), # "Fəaliyyətlər" could be used but "Əməliyyatlar" is standard for transaction actions in finance
    ("overview", "Overview", "İcmal"),
    ("thisMonth", "This month", "Bu ay"),
    ("expense", "Expense", "Xərc")
]

# 1. Add to L10n.swift
l10n_path = "/Users/aplle/Desktop/swift learning/FinaLit/FinaLit/Core/Localization/L10n.swift"
with open(l10n_path, "r") as f:
    l10n_content = f.read()

injection_points = "    public enum Main {\n"
lines_to_inject = ""
for key, en_str, az_str in new_keys:
    lines_to_inject += f'        public static let {key}: LocalizedStringKey = "main.{key}"\n'

l10n_content = l10n_content.replace(injection_points, injection_points + lines_to_inject)

with open(l10n_path, "w") as f:
    f.write(l10n_content)

# 2. Add to en.lproj/Localizable.strings
en_path = "/Users/aplle/Desktop/swift learning/FinaLit/FinaLit/App/en.lproj/Localizable.strings"
with open(en_path, "a") as f:
    f.write("\n")
    for key, en_str, az_str in new_keys:
        f.write(f'"main.{key}" = "{en_str}";\n')

# 3. Add to az.lproj/Localizable.strings
az_path = "/Users/aplle/Desktop/swift learning/FinaLit/FinaLit/App/az.lproj/Localizable.strings"
with open(az_path, "a") as f:
    f.write("\n")
    for key, en_str, az_str in new_keys:
        f.write(f'"main.{key}" = "{az_str}";\n')

print("Injected new keys successfully.")
