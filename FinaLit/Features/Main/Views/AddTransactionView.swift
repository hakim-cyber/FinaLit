//
//  AddTransactionView.swift
//  FinaLit
//
//  Created by aplle on 2/20/26.
//


// AddTransactionView.swift
// Features/Main/Views/

import SwiftUI

struct AddTransactionView: View {
    @Environment(MainViewModel.self)          private var mainVM
    @Environment(Coordinator<MainPages>.self) private var coordinator

    var body: some View {
        ZStack(alignment: .bottom) {
            Color(hex: "0A0A0F").ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {

                    // ── Type toggle ────────────────────────────────────────
                    typeToggle
                        .padding(.top, 8)

                    // ── Amount ─────────────────────────────────────────────
                    amountInput

                    // ── Category ───────────────────────────────────────────
                    categoryGrid

                    // ── Note ───────────────────────────────────────────────
                    noteInput

                    // ── Date ───────────────────────────────────────────────
                    dateInput

                    // ── Recurring toggle ───────────────────────────────────
                    recurringToggle

                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }

            // ── Save button ────────────────────────────────────────────────
            VStack(spacing: 0) {
                LinearGradient(
                    colors: [Color(hex: "0A0A0F").opacity(0), Color(hex: "0A0A0F")],
                    startPoint: .top, endPoint: .bottom
                )
                .frame(height: 30)

                Button {
                    Task {
                        let saved = await mainVM.addTransaction()
                        if saved { coordinator.pop(.sheet) }
                    }
                } label: {
                    HStack {
                        Text("Save Transaction")
                            .font(.system(size: 16, design: .monospaced))
                        if mainVM.isSubmitting {
                            ProgressView().tint(.white).scaleEffect(0.8)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        mainVM.isFormValid
                            ? LinearGradient(
                                colors: [Color(hex: "6366F1"), Color(hex: "4F46E5")],
                                startPoint: .leading, endPoint: .trailing
                              )
                            : LinearGradient(
                                colors: [Color(hex: "1F2937"), Color(hex: "1F2937")],
                                startPoint: .leading, endPoint: .trailing
                              )
                    )
                    .foregroundStyle(mainVM.isFormValid ? .white : Color(hex: "374151"))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .disabled(!mainVM.isFormValid || mainVM.isSubmitting)
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
                .background(Color(hex: "0A0A0F"))
            }
        }
        .onDisappear { mainVM.clearForm() }
        .alert("Error", isPresented: .constant(mainVM.errorMessage != nil)) {
            Button("OK") { mainVM.clearError() }
        } message: { Text(mainVM.errorMessage ?? "") }
    }

    // MARK: - Type Toggle
    private var typeToggle: some View {
        HStack(spacing: 0) {
            ForEach(TransactionType.allCases, id: \.self) { type in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        mainVM.setFormType(type)
                    }
                } label: {
                    Text(type == .expense ? "Expense" : "Income")
                        .font(.system(size: 15, design: .monospaced))
                        .foregroundStyle(mainVM.formType == type ? .white : Color(hex: "4B5563"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            mainVM.formType == type
                                ? (type == .expense ? Color(hex: "F87171") : Color(hex: "10B981")).opacity(0.2)
                                : Color.clear
                        )
                }
            }
        }
        .background(Color(hex: "111118"))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "1F2937"), lineWidth: 1))
    }

    // MARK: - Amount Input
    private var amountInput: some View {
        @Bindable var mainVM = mainVM

        return VStack(alignment: .leading, spacing: 8) {
            Text("AMOUNT")
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundStyle(Color(hex: "4B5563"))

            HStack(alignment: .center, spacing: 4) {
                Text(AppRegion.currencySymbol)
                    .font(.system(size: 36, weight: .light, design: .serif))
                    .foregroundStyle(Color(hex: "374151"))
                TextField("0", text: $mainVM.formAmount)
                    .font(.system(size: 36, weight: .light, design: .serif))
                    .foregroundStyle(.white)
                    .keyboardType(.decimalPad)
                    .tint(Color(hex: "6366F1"))
            }
            .padding(.vertical, 12)

            Divider().background(Color(hex: "1F2937"))
        }
    }

    // MARK: - Category Grid
    private var categoryGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("CATEGORY")
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundStyle(Color(hex: "4B5563"))

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
                ForEach(mainVM.availableCategories) { category in
                    CategoryChip(
                        category:   category,
                        isSelected: mainVM.formCategory == category
                    ) {
                        mainVM.formCategory = category
                    }
                }
            }
        }
    }

    // MARK: - Note Input
    private var noteInput: some View {
        @Bindable var mainVM = mainVM

        return VStack(alignment: .leading, spacing: 8) {
            Text("NOTE (OPTIONAL)")
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundStyle(Color(hex: "4B5563"))
            TextField("What was this for?", text: $mainVM.formNote)
                .font(.system(size: 15, design: .serif))
                .foregroundStyle(.white)
                .padding(14)
                .background(Color(hex: "111118"))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "1F2937"), lineWidth: 1))
        }
    }

    // MARK: - Date Input
    private var dateInput: some View {
        @Bindable var mainVM = mainVM

        return VStack(alignment: .leading, spacing: 8) {
            Text("DATE")
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundStyle(Color(hex: "4B5563"))
            DatePicker("", selection: $mainVM.formDate, displayedComponents: .date)
                .datePickerStyle(.compact)
                .tint(Color(hex: "6366F1"))
                .colorScheme(.dark)
        }
    }

    // MARK: - Recurring Toggle
    private var recurringToggle: some View {
        @Bindable var mainVM = mainVM

        return HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text("RECURRING MONTHLY")
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Color(hex: "4B5563"))
                Text("Mark rent, salary, subscriptions")
                    .font(.system(size: 12, design: .serif))
                    .foregroundStyle(Color(hex: "374151"))
            }
            Spacer()
            Toggle("", isOn: $mainVM.formIsRecurring)
                .tint(Color(hex: "6366F1"))
        }
    }
}

// MARK: - Category Chip
struct CategoryChip: View {
    let category:   TransactionCategory
    let isSelected: Bool
    let onTap:      () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                Image(systemName: category.icon)
                    .font(.system(size: 16))
                    .foregroundStyle(isSelected ? Color(hex: category.color) : Color(hex: "4B5563"))
                Text(category.rawValue.components(separatedBy: " ").first ?? category.rawValue)
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(isSelected ? Color(hex: category.color) : Color(hex: "4B5563"))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? Color(hex: category.color).opacity(0.12) : Color(hex: "111118"))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(
                        isSelected ? Color(hex: category.color).opacity(0.5) : Color(hex: "1F2937"),
                        lineWidth: 1
                    )
            )
        }
    }
}
