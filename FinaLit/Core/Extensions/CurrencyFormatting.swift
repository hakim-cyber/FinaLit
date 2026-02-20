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
