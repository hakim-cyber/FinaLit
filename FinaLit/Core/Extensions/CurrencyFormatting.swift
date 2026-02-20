//
//  CurrencyFormatting.swift
//  FinaLit
//
//  Azerbaijan-first locale and currency helpers.
//

import Foundation

enum AppRegion {
    static let localeIdentifier = "az_AZ"
    static let currencyCode = "AZN"
    static let currencySymbol = "₼"
    static let defaultCountry = "Azerbaijan"

    static var locale: Locale {
        Locale(identifier: localeIdentifier)
    }
}

func formatAmount(_ value: Double) -> String {
    let formatter = NumberFormatter()
    formatter.locale = AppRegion.locale
    formatter.numberStyle = .decimal
    formatter.maximumFractionDigits = 2
    formatter.minimumFractionDigits = 0
    return formatter.string(from: NSNumber(value: value)) ?? String(format: "%.2f", value)
}

func formatCurrency(_ value: Double) -> String {
    let formatter = NumberFormatter()
    formatter.locale = AppRegion.locale
    formatter.numberStyle = .currency
    formatter.currencyCode = AppRegion.currencyCode
    formatter.currencySymbol = AppRegion.currencySymbol
    formatter.maximumFractionDigits = 2
    formatter.minimumFractionDigits = 0
    return formatter.string(from: NSNumber(value: value)) ?? "\(AppRegion.currencySymbol)\(formatAmount(value))"
}

func formatSignedCurrency(_ value: Double) -> String {
    let prefix = value >= 0 ? "+" : "-"
    return "\(prefix)\(formatCurrency(abs(value)))"
}

func formatSignedCurrency(amount: Double, isIncome: Bool) -> String {
    let prefix = isIncome ? "+" : "-"
    return "\(prefix)\(formatCurrency(abs(amount)))"
}

/// Parses user-entered money/decimal text across common locale formats.
/// Supports values like: 1200, 1,200.50, 1.200,50, ₼1 200,50
func parseMonetaryInput(_ rawValue: String) -> Double? {
    let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return nil }

    let withoutCurrency = trimmed
        .replacingOccurrences(of: AppRegion.currencySymbol, with: "")
        .replacingOccurrences(of: "$", with: "")
        .replacingOccurrences(of: "€", with: "")
        .replacingOccurrences(of: "£", with: "")
        .replacingOccurrences(of: "¥", with: "")
        .replacingOccurrences(of: "\u{00A0}", with: " ")
        .replacingOccurrences(of: " ", with: "")

    let locales: [Locale] = [
        AppRegion.locale,
        .current,
        Locale(identifier: "en_US_POSIX")
    ]

    for locale in locales {
        let decimal = NumberFormatter()
        decimal.locale = locale
        decimal.numberStyle = .decimal
        if let number = decimal.number(from: withoutCurrency) {
            return number.doubleValue
        }

        let currency = NumberFormatter()
        currency.locale = locale
        currency.numberStyle = .currency
        if let number = currency.number(from: withoutCurrency) {
            return number.doubleValue
        }
    }

    guard let normalized = normalizedNumericString(withoutCurrency) else { return nil }
    return Double(normalized)
}

private func normalizedNumericString(_ value: String) -> String? {
    let allowed = CharacterSet(charactersIn: "0123456789,.-")
    let filteredScalars = value.unicodeScalars.filter { allowed.contains($0) }
    var filtered = String(String.UnicodeScalarView(filteredScalars))
    guard !filtered.isEmpty else { return nil }

    let isNegative = filtered.first == "-"
    filtered.removeAll(where: { $0 == "-" })
    guard !filtered.isEmpty else { return nil }

    let lastDot = filtered.lastIndex(of: ".")
    let lastComma = filtered.lastIndex(of: ",")
    let decimalSeparatorIndex: String.Index? = {
        switch (lastDot, lastComma) {
        case let (dot?, comma?):
            return dot > comma ? dot : comma
        case let (dot?, nil):
            return dot
        case let (nil, comma?):
            return comma
        default:
            return nil
        }
    }()

    var output = ""
    for index in filtered.indices {
        let character = filtered[index]
        if character.isNumber {
            output.append(character)
        } else if let decimalSeparatorIndex, index == decimalSeparatorIndex {
            output.append(".")
        }
    }

    guard !output.isEmpty else { return nil }
    return isNegative ? "-\(output)" : output
}
