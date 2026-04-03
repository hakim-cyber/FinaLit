//
//  BudgetCategoryCard.swift
//  FinaLit
//

import SwiftUI

struct BudgetCategoryCard: View {
    let category: TransactionCategory
    let spent: Double
    let limit: Double?
    let isEditing: Bool
    @Binding var editingText: String

    private var usage: Double {
        guard let limit, limit > 0 else { return 0 }
        return min(spent / limit, 1)
    }

    private var isOver: Bool {
        guard let limit else { return false }
        return spent > limit
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(hex: category.color).opacity(0.12))
                        .frame(width: 38, height: 38)
                    Image(systemName: category.icon)
                        .font(.system(size: 15))
                        .foregroundStyle(Color(hex: category.color))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(category.rawValue)
                        .font(.system(size: 15))
                        .foregroundStyle(.white)
                    Text("Spent: \(formatCurrency(spent))")
                        .font(.system(size: 11))
                        .foregroundStyle(Color(hex: "4B5563"))
                }

                Spacer()

                if isEditing {
                    HStack(spacing: 4) {
                        Text(AppRegion.currencySymbol)
                            .font(.system(size: 14))
                            .foregroundStyle(Color(hex: "4B5563"))
                        TextField("Limit", text: $editingText)
                            .font(.system(size: 14))
                            .foregroundStyle(.white)
                            .keyboardType(.decimalPad)
                            .frame(width: 70)
                            .multilineTextAlignment(.trailing)
                    }
                } else if let limit {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(formatCurrency(limit))
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(isOver ? Color(hex: "F87171") : .white)
                        Text("limit")
                            .font(.system(size: 10))
                            .foregroundStyle(Color(hex: "4B5563"))
                    }
                } else {
                    Text("No limit")
                        .font(.system(size: 12))
                        .foregroundStyle(Color(hex: "374151"))
                }
            }

            if limit != nil && !isEditing {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color(hex: "1F2937"))
                            .frame(height: 5)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(isOver ? Color(hex: "F87171") : Color(hex: category.color))
                            .frame(width: geometry.size.width * CGFloat(usage), height: 5)
                            .animation(.easeInOut(duration: 0.4), value: usage)
                    }
                }
                .frame(height: 5)
            }
        }
        .padding(14)
        .background(Color(hex: "111118"))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(
                    isOver ? Color(hex: "F87171").opacity(0.3) : Color(hex: "1F2937"),
                    lineWidth: 1
                )
        )
    }
}
