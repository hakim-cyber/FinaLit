import os

new_keys_main = [
    ("savings", "Savings", "Yığımlar"),
    ("addDebt", "Add Debt", "Borc əlavə et"),
    ("createFirstDebt", "Create first debt", "İlk borcuna başla"),
    ("remaining", "remaining", "qaldı"),
    ("contributeNow", "Contribute now", "İndi vəsait əlavə et"),
    ("closeMonth", "Close Month", "Ayı bağla"),
    ("seeAll", "See all", "Hamısına bax"),
    ("monthlyOverview", "Monthly overview", "Aylıq icmal"),
    ("dailyAverage", "Daily Average", "Gündəlik ortalama"),
    ("netBalance", "Net Balance", "Xalis balans"),
    ("discretionary", "Discretionary", "Sərbəst xərc"),
    ("vsLastMonth", "vs Last Month", "Keçən ayla"),
    ("smartInsights", "Smart insights", "Ağıllı insaytlar"),
    ("spendingHistory", "Spending history", "Xərcləmə tarixçəsi"),
    ("recentTransactions", "Recent transactions", "Son əməliyyatlar"),
    ("allTransactions", "All transactions", "Bütün əməliyyatlar"),
    ("note", "Note", "Qeyd"),
    ("recurring", "Recurring", "Təkrarlanan"),
    ("insightOverspending", "You're overspending", "Həddindən artıq xərcləyirsiniz"),
    ("insightLowEmergency", "Low emergency fund", "Aşağı təcili fondu"),
    ("insightLowSavings", "Low savings rate", "Aşağı yığım faizi"),
    ("insightHighFood", "High food spending", "Yüksək qida xərci"),
    ("insightHighDiscretionary", "High discretionary spending", "Yüksək sərbəst xərcləmə"),
    ("insightExpensesIncreased", "Expenses increased", "Xərclər artdı"),
    ("insightGreatSavings", "Great savings rate", "Əla yığım faizi"),
    ("insightSolidEmergency", "Solid emergency fund", "Güclü təcili ehtiyat fondu"),
    ("insightSpendingDecreased", "Spending decreased", "Xərclər azaldı"),
    ("insightNoIncome", "No income logged", "Gəlir qeydə alınmayıb"),
    ("insightStartTracking", "Start tracking", "İzləməyə başla"),
    ("insightStartTrackingDesc", "Add your first transaction to see your financial picture.", "Maliyyə vəziyyətinizi görmək üçün ilk əməliyyatınızı əlavə edin."),
    ("insightNoIncomeDesc", "Add your income transactions to get accurate savings rate and insights.", "Dəqiq yığım dərəcəsi və insaytlar üçün gəlir əməliyyatlarınızı əlavə edin."),
]

new_keys_onboarding = [
    ("monthlyExpenses", "Monthly expenses", "Aylıq xərclər"),
    ("splitRecurringFlexible", "Split your recurring and flexible spending.", "Təkrarlanan və dəyişən xərclərini böl."),
    ("fixedExpenses", "Fixed expenses", "Sabit xərclər"),
    ("variableExpenses", "Variable expenses", "Dəyişən xərclər"),
    ("incomeStabilityHeader", "Income and stability", "Gəlir və sabitlik"),
    ("setMonthlyIncome", "Set your monthly income and tell us how consistent it is.", "Aylıq gəlirini təyin et və onun nə dərəcədə sabit olduğunu bildir."),
    ("monthlyIncome", "Monthly income", "Aylıq gəlir"),
    ("variable", "Variable", "Dəyişən")
]

new_keys_profile = [
    ("financialProfile", "Financial Profile", "Maliyyə Profili"),
    ("updateRealWorldNumbers", "Update your real-world numbers to keep advice relevant.", "Məsləhətlərin dəqiq olması üçün real göstəricilərini yenilə."),
    ("saveChanges", "Save Changes", "Dəyişiklikləri yadda saxla"),
    ("noDebt", "No debt", "Borc yoxdur"),
    ("haveDebt", "I have debt", "Borcum var"),
    ("debtAmountField", "Debt amount", "Borc məbləği"),
    ("sessionExpired", "Session expired. Please log in again.", "Sessiya bitdi. Yenidən daxil ol."),
    ("incomeGreaterThanZero", "Monthly income must be greater than 0.", "Aylıq gəlir 0-dan böyük olmalıdır."),
    ("debtGreaterThanZero", "Debt amount must be greater than 0 when debt is enabled.", "Borc mövcuddursa, məbləğ 0-dan böyük olmalıdır."),
    ("financialProfileUpdated", "Financial profile updated.", "Maliyyə profili yeniləndi.")
]

new_keys_common = [
    ("yes", "Yes", "Bəli"),
    ("no", "No", "Xeyr")
]

# 1. Add to L10n.swift
l10n_path = "/Users/aplle/Desktop/swift learning/FinaLit/FinaLit/Core/Localization/L10n.swift"
with open(l10n_path, "r") as f:
    l10n_content = f.read()

def inject(array, enum_name):
    global l10n_content
    injection_points = f"    public enum {enum_name} {{\n"
    lines_to_inject = ""
    for key, _, _ in array:
        lines_to_inject += f'        public static let {key}: LocalizedStringKey = "{enum_name.lower()}.{key}"\n'
    l10n_content = l10n_content.replace(injection_points, injection_points + lines_to_inject)

inject(new_keys_main, "Main")
inject(new_keys_onboarding, "Onboarding")
inject(new_keys_profile, "Profile")
inject(new_keys_common, "Common")

with open(l10n_path, "w") as f:
    f.write(l10n_content)

# 2. Add to en.lproj/Localizable.strings
en_path = "/Users/aplle/Desktop/swift learning/FinaLit/FinaLit/App/en.lproj/Localizable.strings"
with open(en_path, "a") as f:
    f.write("\n")
    for arr, prefix in [(new_keys_main, "main"), (new_keys_onboarding, "onboarding"), (new_keys_profile, "profile"), (new_keys_common, "common")]:
        for key, en_str, _ in arr:
            f.write(f'"{prefix}.{key}" = "{en_str}";\n')

# 3. Add to az.lproj/Localizable.strings
az_path = "/Users/aplle/Desktop/swift learning/FinaLit/FinaLit/App/az.lproj/Localizable.strings"
with open(az_path, "a") as f:
    f.write("\n")
    for arr, prefix in [(new_keys_main, "main"), (new_keys_onboarding, "onboarding"), (new_keys_profile, "profile"), (new_keys_common, "common")]:
        for key, _, az_str in arr:
            f.write(f'"{prefix}.{key}" = "{az_str}";\n')

print("Injected new keys successfully.")
