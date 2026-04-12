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
        ZStack {
            AppTheme.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    typeToggle
                        .padding(.top, 8)

                    amountInput

                    categoryGrid

                    noteInput

                    dateInput

                    recurringToggle

                    Spacer(minLength: 24)
                }
                .padding(.horizontal, AppTheme.Spacing.screen)
                .padding(.top, 20)
            }
        }
        .safeAreaInset(edge: .bottom) {
            Button {
                Task {
                    let saved = await mainVM.addTransaction()
                    if saved { coordinator.pop(.sheet) }
                }
            } label: {
                HStack(spacing: 10) {
                    Text(L10n.Main.saveTransaction)
                    if mainVM.isSubmitting {
                        ProgressView()
                            .tint(AppTheme.inverseText)
                            .scaleEffect(0.8)
                    }
                }
            }
            .buttonStyle(AppFilledButtonStyle(tone: .accent))
            .disabled(!mainVM.isFormValid || mainVM.isSubmitting)
            .padding(.horizontal, AppTheme.Spacing.screen)
            .padding(.top, 8)
            .padding(.bottom, 8)
            .background(AppTheme.background.opacity(0.94))
        }
        .onDisappear { mainVM.clearForm() }
        .onAppear { mainVM.prepareTransactionFormForSelectedMonth() }
        .alert(L10n.Admin.error, isPresented: isShowingErrorAlert) {
            Button(L10n.Auth.ok) { mainVM.clearError() }
        } message: { Text(mainVM.errorMessage ?? "") }
            .presentationDragIndicator(.visible)
    }

    private var isShowingErrorAlert: Binding<Bool> {
        Binding(
            get: { mainVM.errorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    mainVM.clearError()
                }
            }
        )
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
                    Text(type == .expense ? L10n.Main.expense : L10n.Main.income)
                        .font(AppTheme.Typography.bodySemibold)
                        .foregroundStyle(mainVM.formType == type ? AppTheme.textPrimary : AppTheme.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            mainVM.formType == type
                                ? (type == .expense ? AppTheme.softFill(for: .danger) : AppTheme.softFill(for: .success))
                                : AppTheme.surfacePrimary
                        )
                }
            }
        }
        .background(AppTheme.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppTheme.separator, lineWidth: 1))
    }

    // MARK: - Amount Input
    private var amountInput: some View {
        @Bindable var mainVM = mainVM

        return VStack(alignment: .leading, spacing: 8) {
            Text(L10n.Main.amount)
                .appFieldLabelStyle()

            HStack(alignment: .center, spacing: 4) {
                Text(AppRegion.currencySymbol)
                    .font(.system(size: 32, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)
                TextField(L10n.Profile.zero, text: $mainVM.formAmount)
                    .font(.system(size: 34, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)
                    .keyboardType(.decimalPad)
                    .tint(AppTheme.accent)
            }
            .padding(.vertical, 12)

            Divider().background(AppTheme.separator)
        }
    }

    // MARK: - Category Grid
    private var categoryGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.Main.category)
                .appFieldLabelStyle()

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
            Text(L10n.Main.noteOptional)
                .appFieldLabelStyle()
            TextField(L10n.Main.whatWasThisFor, text: $mainVM.formNote)
                .appInputStyle()
        }
    }

    // MARK: - Date Input
    private var dateInput: some View {
        @Bindable var mainVM = mainVM

        return VStack(alignment: .leading, spacing: 8) {
            Text(L10n.Main.date)
                .appFieldLabelStyle()
            DatePicker("", selection: $mainVM.formDate, displayedComponents: .date)
                .datePickerStyle(.compact)
                .tint(AppTheme.accent)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(AppTheme.surfacePrimary, in: RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                        .stroke(AppTheme.separator, lineWidth: 1)
                )
        }
    }

    // MARK: - Recurring Toggle
    private var recurringToggle: some View {
        @Bindable var mainVM = mainVM

        return HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(L10n.Main.recurringMonthly)
                    .appFieldLabelStyle()
                Text(L10n.Main.markRentSalarySubscriptions)
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textSecondary)
            }
            Spacer()
            Toggle("", isOn: $mainVM.formIsRecurring)
                .tint(AppTheme.accent)
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
                    .foregroundStyle(isSelected ? AppTheme.tint(for: category.tone) : AppTheme.textSecondary)
                Text(category.localizedName )
                    .font(.system(size: 9))
                    .foregroundStyle(isSelected ? AppTheme.tint(for: category.tone) : AppTheme.textSecondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? AppTheme.softFill(for: category.tone) : AppTheme.surfacePrimary)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(
                        isSelected ? AppTheme.softBorder(for: category.tone) : AppTheme.separator,
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
    }
}
