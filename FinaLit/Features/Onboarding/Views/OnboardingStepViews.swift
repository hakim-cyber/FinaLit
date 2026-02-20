import SwiftUI

// MARK: - Step 1

struct OnboardingPersonalInfoView: View {
    @Environment(OnboardingViewModel.self) private var viewModel
    @Environment(Coordinator<OnboardingPages>.self) private var coordinator

    private let countries = [
        "Azerbaijan","Turkey","United States", "Canada", "United Kingdom", "Germany"
    ]

    var body: some View {
        @Bindable var viewModel = viewModel

        OnboardingStepScaffold(
            page: .personalInfo,
            title: "Tell us about you",
            subtitle: "We use this to personalize your financial assistant.",
            errorMessage: viewModel.errorMessage,
            isLoading: viewModel.isLoading,
            primaryTitle: "Continue",
            isPrimaryEnabled: viewModel.isStep1Valid,
            onPrimaryTap: {
                Task {
                    if await viewModel.saveStep1PersonalInfo() {
                        coordinator.push(.employmentStatus)
                    }
                }
            }
        ) {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Name")
                        .onboardingFieldLabelStyle()
                    TextField("Your name", text: $viewModel.name)
                        .textInputAutocapitalization(.words)
                        .onboardingInputStyle()
                }

                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Age")
                            .onboardingFieldLabelStyle()
                        Spacer()
                        Text("\(Int(viewModel.age.rounded()))")
                            .font(.system(size: 13, weight: .semibold, design: .monospaced))
                            .foregroundStyle(OnboardingPalette.accent)
                    }
                    Slider(value: $viewModel.age, in: 13...70, step: 1)
                        .tint(OnboardingPalette.accent)
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Country")
                        .onboardingFieldLabelStyle()

                    AdaptiveChips(
                        items: countries,
                        selection: viewModel.country,
                        onTap: { country in
                            viewModel.country = country
                            viewModel.clearError()
                        }
                    )

                    TextField("Or enter your country", text: $viewModel.country)
                        .textInputAutocapitalization(.words)
                        .onboardingInputStyle()
                }
            }
            .onChange(of: viewModel.name) { _, _ in viewModel.clearError() }
            .onChange(of: viewModel.country) { _, _ in viewModel.clearError() }
        }
    }
}

// MARK: - Step 2

struct OnboardingEmploymentStatusView: View {
    @Environment(OnboardingViewModel.self) private var viewModel
    @Environment(Coordinator<OnboardingPages>.self) private var coordinator

    var body: some View {
        @Bindable var viewModel = viewModel

        OnboardingStepScaffold(
            page: .employmentStatus,
            title: "What's your employment status?",
            subtitle: "This helps us estimate realistic monthly cash flow.",
            errorMessage: viewModel.errorMessage,
            isLoading: viewModel.isLoading,
            primaryTitle: "Continue",
            isPrimaryEnabled: true,
            onPrimaryTap: {
                Task {
                    if await viewModel.saveStep2Employment() {
                        coordinator.push(.incomeAndStability)
                    }
                }
            }
        ) {
            VStack(spacing: 10) {
                ForEach(EmploymentStatus.allCases) { status in
                    SelectableRowCard(
                        title: status.rawValue,
                        subtitle: status.description,
                        isSelected: viewModel.employmentStatus == status,
                        accent: OnboardingPalette.accent,
                        icon: "briefcase.fill"
                    ) {
                        viewModel.employmentStatus = status
                        viewModel.clearError()
                    }
                }
            }
        }
    }
}

// MARK: - Step 3

struct OnboardingIncomeStabilityView: View {
    @Environment(OnboardingViewModel.self) private var viewModel
    @Environment(Coordinator<OnboardingPages>.self) private var coordinator

    var body: some View {
        @Bindable var viewModel = viewModel

        OnboardingStepScaffold(
            page: .incomeAndStability,
            title: "Income and stability",
            subtitle: "Set your monthly income and tell us how consistent it is.",
            errorMessage: viewModel.errorMessage,
            isLoading: viewModel.isLoading,
            primaryTitle: "Continue",
            isPrimaryEnabled: viewModel.isStep3Valid,
            onPrimaryTap: {
                Task {
                    if await viewModel.saveStep3Income() {
                        coordinator.push(.monthlyExpenses)
                    }
                }
            }
        ) {
            VStack(alignment: .leading, spacing: 18) {
                MoneySlider(
                    title: "Monthly income",
                    value: $viewModel.monthlyIncome,
                    range: 0...20000,
                    step: 50,
                    tint: .green
                )

                VStack(alignment: .leading, spacing: 10) {
                    Text("Income stability")
                        .onboardingFieldLabelStyle()

                    HStack(spacing: 10) {
                        TogglePill(
                            title: "Stable",
                            isSelected: viewModel.incomeStability == .stable,
                            tint: OnboardingPalette.accent
                        ) {
                            viewModel.incomeStability = .stable
                            viewModel.clearError()
                        }

                        TogglePill(
                            title: "Variable",
                            isSelected: viewModel.incomeStability == .variable,
                            tint: .orange
                        ) {
                            viewModel.incomeStability = .variable
                            viewModel.clearError()
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Step 4

struct OnboardingExpensesView: View {
    @Environment(OnboardingViewModel.self) private var viewModel
    @Environment(Coordinator<OnboardingPages>.self) private var coordinator

    var body: some View {
        @Bindable var viewModel = viewModel

        OnboardingStepScaffold(
            page: .monthlyExpenses,
            title: "Monthly expenses",
            subtitle: "Split your recurring and flexible spending.",
            errorMessage: viewModel.errorMessage,
            isLoading: viewModel.isLoading,
            primaryTitle: "Continue",
            isPrimaryEnabled: viewModel.isStep4Valid,
            onPrimaryTap: {
                Task {
                    if await viewModel.saveStep4Expenses() {
                        coordinator.push(.savingsAndEmergencyFund)
                    }
                }
            }
        ) {
            VStack(alignment: .leading, spacing: 16) {
                MoneySlider(
                    title: "Fixed expenses",
                    value: $viewModel.monthlyFixedExpenses,
                    range: 0...10000,
                    step: 25,
                    tint: OnboardingPalette.accent
                )

                MoneySlider(
                    title: "Variable expenses",
                    value: $viewModel.monthlyVariableExpenses,
                    range: 0...10000,
                    step: 25,
                    tint: .orange
                )
            }
        }
    }
}

// MARK: - Step 5

struct OnboardingSavingsEmergencyView: View {
    @Environment(OnboardingViewModel.self) private var viewModel
    @Environment(Coordinator<OnboardingPages>.self) private var coordinator

    var body: some View {
        @Bindable var viewModel = viewModel

        OnboardingStepScaffold(
            page: .savingsAndEmergencyFund,
            title: "Savings and emergency buffer",
            subtitle: "A quick view of your safety net today.",
            errorMessage: viewModel.errorMessage,
            isLoading: viewModel.isLoading,
            primaryTitle: "Continue",
            isPrimaryEnabled: true,
            onPrimaryTap: {
                Task {
                    if await viewModel.saveStep5Savings() {
                        coordinator.push(.debt)
                    }
                }
            }
        ) {
            VStack(alignment: .leading, spacing: 18) {
                MoneySlider(
                    title: "Current savings",
                    value: $viewModel.currentSavings,
                    range: 0...200000,
                    step: 100,
                    tint: .green
                )

                VStack(alignment: .leading, spacing: 10) {
                    Text("Emergency fund")
                        .onboardingFieldLabelStyle()

                    HStack {
                        Text("Months covered")
                            .foregroundStyle(OnboardingPalette.muted)
                        Spacer()
                        Stepper(value: $viewModel.emergencyFundMonths, in: 0...24) {
                            Text("\(viewModel.emergencyFundMonths) months")
                                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                                .foregroundStyle(.white)
                        }
                    }
                    .padding(14)
                    .background(OnboardingPalette.surface, in: RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(OnboardingPalette.border, lineWidth: 1)
                    )
                }
            }
        }
    }
}

// MARK: - Step 6

struct OnboardingDebtView: View {
    @Environment(OnboardingViewModel.self) private var viewModel
    @Environment(Coordinator<OnboardingPages>.self) private var coordinator

    var body: some View {
        OnboardingStepScaffold(
            page: .debt,
            title: "Do you currently have debt?",
            subtitle: "We use this to balance payoff strategy with savings goals.",
            errorMessage: viewModel.errorMessage,
            isLoading: viewModel.isLoading,
            primaryTitle: "Continue",
            isPrimaryEnabled: viewModel.isStep6Valid,
            onPrimaryTap: {
                Task {
                    if await viewModel.saveStep6Debt() {
                        coordinator.push(.riskAndInvesting)
                    }
                }
            }
        ) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 10) {
                    TogglePill(title: "No debt", isSelected: !viewModel.hasDebt, tint: .green) {
                        viewModel.setHasDebt(false)
                    }

                    TogglePill(title: "I have debt", isSelected: viewModel.hasDebt, tint: .red) {
                        viewModel.setHasDebt(true)
                    }
                }

                if viewModel.hasDebt {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Debt accounts")
                            .onboardingFieldLabelStyle()

                        ForEach(viewModel.debtEntries) { debtEntry in
                            OnboardingDebtEntryCard(
                                accountName: Binding(
                                    get: { viewModel.debtEntryName(debtEntry.id) },
                                    set: { viewModel.updateDebtEntryName(debtEntry.id, value: $0) }
                                ),
                                amountText: Binding(
                                    get: { viewModel.debtEntryAmountText(debtEntry.id) },
                                    set: { viewModel.updateDebtEntryAmount(debtEntry.id, value: $0) }
                                ),
                                canDelete: viewModel.debtEntries.count > 1,
                                onDelete: { viewModel.removeDebtEntry(debtEntry.id) }
                            )
                        }

                        Button {
                            viewModel.addDebtEntry()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "plus.circle.fill")
                                Text("Add another debt")
                            }
                            .font(.system(size: 13, weight: .semibold, design: .monospaced))
                            .foregroundStyle(Color(hex: "F87171"))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color(hex: "F87171").opacity(0.12))
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)

                        HStack {
                            Text("Total debt")
                                .onboardingFieldLabelStyle()
                            Spacer()
                            Text(currency(viewModel.totalDebtAmount))
                                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                                .foregroundStyle(.white)
                        }
                        .padding(12)
                        .background(OnboardingPalette.background.opacity(0.8), in: RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(OnboardingPalette.border, lineWidth: 1)
                        )
                    }
                }
            }
        }
    }
}

private struct OnboardingDebtEntryCard: View {
    @Binding var accountName: String
    @Binding var amountText: String
    let canDelete: Bool
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                TextField("Debt account name", text: $accountName)
                    .textInputAutocapitalization(.words)
                    .onboardingInputStyle()

                if canDelete {
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color(hex: "F87171"))
                            .frame(width: 40, height: 40)
                            .background(Color(hex: "450A0A"), in: RoundedRectangle(cornerRadius: 10))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color(hex: "7F1D1D"), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }

            TextField("Debt amount", text: $amountText)
                .keyboardType(.decimalPad)
                .onboardingInputStyle()
        }
        .padding(12)
        .background(OnboardingPalette.surface, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(OnboardingPalette.border, lineWidth: 1)
        )
    }
}

// MARK: - Step 7

struct OnboardingRiskInterestView: View {
    @Environment(OnboardingViewModel.self) private var viewModel
    @Environment(Coordinator<OnboardingPages>.self) private var coordinator

    var body: some View {
        @Bindable var viewModel = viewModel

        OnboardingStepScaffold(
            page: .riskAndInvesting,
            title: "Risk and investing interest",
            subtitle: "We'll keep recommendations aligned with your comfort level.",
            errorMessage: viewModel.errorMessage,
            isLoading: viewModel.isLoading,
            primaryTitle: "Continue",
            isPrimaryEnabled: true,
            onPrimaryTap: {
                Task {
                    if await viewModel.saveStep7Risk() {
                        coordinator.push(.shortTermGoal)
                    }
                }
            }
        ) {
            VStack(alignment: .leading, spacing: 14) {
                Text("Risk tolerance")
                    .onboardingFieldLabelStyle()

                VStack(spacing: 10) {
                    RiskSelectionCard(
                        title: "Low",
                        subtitle: "Safety first, steady progress",
                        isSelected: viewModel.riskTolerance == .low,
                        tint: .green
                    ) {
                        viewModel.riskTolerance = .low
                        viewModel.clearError()
                    }

                    RiskSelectionCard(
                        title: "Medium",
                        subtitle: "Balanced risk and growth",
                        isSelected: viewModel.riskTolerance == .medium,
                        tint: .orange
                    ) {
                        viewModel.riskTolerance = .medium
                        viewModel.clearError()
                    }

                    RiskSelectionCard(
                        title: "High",
                        subtitle: "Higher volatility for higher potential",
                        isSelected: viewModel.riskTolerance == .high,
                        tint: .red
                    ) {
                        viewModel.riskTolerance = .high
                        viewModel.clearError()
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Interested in investing?")
                        .onboardingFieldLabelStyle()

                    HStack(spacing: 10) {
                        TogglePill(title: "Yes", isSelected: viewModel.interestedInInvesting, tint: OnboardingPalette.accent) {
                            viewModel.interestedInInvesting = true
                            viewModel.clearError()
                        }
                        TogglePill(title: "Not now", isSelected: !viewModel.interestedInInvesting, tint: OnboardingPalette.muted) {
                            viewModel.interestedInInvesting = false
                            viewModel.clearError()
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Step 8

struct OnboardingShortTermGoalView: View {
    @Environment(OnboardingViewModel.self) private var viewModel
    @Environment(Coordinator<OnboardingPages>.self) private var coordinator

    private let suggestions = [
        "Build a \(AppRegion.currencySymbol)1,000 emergency fund",
        "Pay off a credit card",
        "Save for a new laptop",
        "Save for a trip",
        "Reduce monthly overspending"
    ]

    var body: some View {
        @Bindable var viewModel = viewModel

        OnboardingStepScaffold(
            page: .shortTermGoal,
            title: "Your short-term goal",
            subtitle: "Pick one quickly or write your own.",
            errorMessage: viewModel.errorMessage,
            isLoading: viewModel.isLoading,
            primaryTitle: "Continue",
            isPrimaryEnabled: viewModel.isStep8Valid,
            onPrimaryTap: {
                Task {
                    if await viewModel.saveStep8ShortTermGoal() {
                        coordinator.push(.longTermGoal)
                    }
                }
            }
        ) {
            VStack(alignment: .leading, spacing: 12) {
                AdaptiveChips(items: suggestions, selection: viewModel.shortTermGoal) { value in
                    viewModel.shortTermGoal = value
                    viewModel.clearError()
                }

                TextField("Type your short-term goal", text: $viewModel.shortTermGoal, axis: .vertical)
                    .lineLimit(2...4)
                    .onboardingTextAreaStyle()
                    .onChange(of: viewModel.shortTermGoal) { _, _ in viewModel.clearError() }
            }
        }
    }
}

// MARK: - Step 9

struct OnboardingLongTermGoalView: View {
    @Environment(OnboardingViewModel.self) private var viewModel
    @Environment(Coordinator<OnboardingPages>.self) private var coordinator

    private let suggestions = [
        "Buy a home",
        "Reach financial independence",
        "Build a 6-figure portfolio",
        "Start a business",
        "Retire early"
    ]

    var body: some View {
        @Bindable var viewModel = viewModel

        OnboardingStepScaffold(
            page: .longTermGoal,
            title: "Your long-term goal",
            subtitle: "This guides strategic recommendations over time.",
            errorMessage: viewModel.errorMessage,
            isLoading: viewModel.isLoading,
            primaryTitle: "Continue",
            isPrimaryEnabled: viewModel.isStep9Valid,
            onPrimaryTap: {
                Task {
                    if await viewModel.saveStep9LongTermGoal() {
                        coordinator.push(.spendingWeaknesses)
                    }
                }
            }
        ) {
            VStack(alignment: .leading, spacing: 12) {
                AdaptiveChips(items: suggestions, selection: viewModel.longTermGoal) { value in
                    viewModel.longTermGoal = value
                    viewModel.clearError()
                }

                TextField("Type your long-term goal", text: $viewModel.longTermGoal, axis: .vertical)
                    .lineLimit(2...4)
                    .onboardingTextAreaStyle()
                    .onChange(of: viewModel.longTermGoal) { _, _ in viewModel.clearError() }
            }
        }
    }
}

// MARK: - Step 10

struct OnboardingSpendingWeaknessesView: View {
    @Environment(OnboardingViewModel.self) private var viewModel
    @Environment(Coordinator<OnboardingPages>.self) private var coordinator

    var body: some View {
        OnboardingStepScaffold(
            page: .spendingWeaknesses,
            title: "Where do you overspend most?",
            subtitle: "Pick up to \(viewModel.maxWeaknessSelections).",
            errorMessage: viewModel.errorMessage,
            isLoading: viewModel.isLoading,
            primaryTitle: "Continue",
            isPrimaryEnabled: viewModel.isStep10Valid,
            onPrimaryTap: {
                if viewModel.validateStep10Weaknesses() {
                    coordinator.push(.hobbies)
                }
            }
        ) {
            VStack(alignment: .leading, spacing: 10) {
                Text("\(viewModel.spendingWeaknesses.count)/\(viewModel.maxWeaknessSelections) selected")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(OnboardingPalette.muted)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 130), spacing: 10)], spacing: 10) {
                    ForEach(SpendingCategory.allCases) { category in
                        let isSelected = viewModel.spendingWeaknesses.contains(category)
                        ChipButton(
                            title: category.rawValue,
                            icon: category.icon,
                            isSelected: isSelected,
                            onTap: {
                                viewModel.toggleWeakness(category)
                            }
                        )
                    }
                }
            }
        }
    }
}

// MARK: - Step 11

struct OnboardingHobbiesView: View {
    @Environment(OnboardingViewModel.self) private var viewModel
    @Environment(Coordinator<OnboardingPages>.self) private var coordinator

    private let hobbies = [
        "Gaming 🎮", "Music 🎵", "Cooking 🍳", "Fitness 💪",
        "Reading 📚", "Travel ✈️", "Photography 📷", "Fashion 👗",
        "Movies 🎬", "Sports ⚽", "Art 🎨", "Other ✏️"
    ]

    var body: some View {
        @Bindable var viewModel = viewModel

        OnboardingStepScaffold(
            page: .hobbies,
            title: "What do you enjoy outside money?",
            subtitle: "Choose up to \(viewModel.maxHobbySelections), or add your own.",
            errorMessage: viewModel.errorMessage,
            isLoading: viewModel.isLoading,
            primaryTitle: "Continue",
            isPrimaryEnabled: viewModel.isStep11Valid,
            onPrimaryTap: {
                if viewModel.validateStep11Hobbies() {
                    coordinator.push(.knowledgeLevel)
                }
            }
        ) {
            VStack(alignment: .leading, spacing: 12) {
                Text("\(viewModel.normalizedHobbies.count)/\(viewModel.maxHobbySelections) selected")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(OnboardingPalette.muted)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 130), spacing: 10)], spacing: 10) {
                    ForEach(hobbies, id: \.self) { hobby in
                        if hobby == "Other ✏️" {
                            ChipButton(
                                title: hobby,
                                icon: "",
                                isSelected: viewModel.isOtherHobbySelected,
                                onTap: {
                                    viewModel.isOtherHobbySelected.toggle()
                                    if !viewModel.isOtherHobbySelected {
                                        viewModel.customHobby = ""
                                    }
                                    viewModel.clearError()
                                }
                            )
                        } else {
                            ChipButton(
                                title: hobby,
                                icon: "",
                                isSelected: viewModel.selectedHobbies.contains(hobby),
                                onTap: {
                                    viewModel.toggleHobby(hobby)
                                }
                            )
                        }
                    }
                }

                if viewModel.isOtherHobbySelected {
                    TextField("Add custom hobby", text: $viewModel.customHobby)
                        .textInputAutocapitalization(.words)
                        .onboardingInputStyle()
                        .onChange(of: viewModel.customHobby) { _, _ in
                            viewModel.clearError()
                        }
                }
            }
        }
    }
}

// MARK: - Step 12

struct OnboardingKnowledgeLevelView: View {
    @Environment(OnboardingViewModel.self) private var viewModel

    var body: some View {
        OnboardingStepScaffold(
            page: .knowledgeLevel,
            title: "How would you rate your financial knowledge?",
            subtitle: "We'll adjust guidance depth and language to match.",
            errorMessage: viewModel.errorMessage,
            isLoading: viewModel.isLoading,
            primaryTitle: "Finish Setup",
            isPrimaryEnabled: true,
            onPrimaryTap: {
                Task {
                    _ = await viewModel.completeOnboarding()
                }
            }
        ) {
            VStack(spacing: 10) {
                KnowledgeLevelCard(
                    title: "Beginner",
                    description: "Simple, practical next steps",
                    level: 0.33,
                    isSelected: viewModel.knowledgeLevel == .beginner
                ) {
                    viewModel.knowledgeLevel = .beginner
                    viewModel.clearError()
                }

                KnowledgeLevelCard(
                    title: "Intermediate",
                    description: "Balanced insights with more detail",
                    level: 0.66,
                    isSelected: viewModel.knowledgeLevel == .intermediate
                ) {
                    viewModel.knowledgeLevel = .intermediate
                    viewModel.clearError()
                }

                KnowledgeLevelCard(
                    title: "Advanced",
                    description: "Higher detail and analytical trade-offs",
                    level: 1.0,
                    isSelected: viewModel.knowledgeLevel == .advanced
                ) {
                    viewModel.knowledgeLevel = .advanced
                    viewModel.clearError()
                }
            }
        }
    }
}

// MARK: - Shared UI

private struct OnboardingStepScaffold<Content: View>: View {
    let page: OnboardingPages
    let title: String
    let subtitle: String
    let errorMessage: String?
    let isLoading: Bool
    let primaryTitle: String
    let isPrimaryEnabled: Bool
    let onPrimaryTap: () -> Void
    @ViewBuilder let content: () -> Content

    @Environment(Coordinator<OnboardingPages>.self) private var coordinator

    var body: some View {
        ZStack {
            OnboardingPalette.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack {
                    VStack(alignment: .leading, spacing: 20) {
                        VStack(spacing: 14) {
                            HStack {
                                if page.stepNumber > 1 {
                                    Button {
                                        coordinator.pop()
                                    } label: {
                                        Image(systemName: "chevron.left")
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundStyle(.white)
                                            .frame(width: 34, height: 34)
                                            .background(OnboardingPalette.background.opacity(0.8), in: RoundedRectangle(cornerRadius: 10))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .stroke(OnboardingPalette.border, lineWidth: 1)
                                            )
                                    }
                                    .buttonStyle(.plain)
                                }

                                Spacer()

                                Text("STEP \(page.stepNumber) OF \(OnboardingPages.totalSteps)")
                                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                    .foregroundStyle(OnboardingPalette.muted)
                            }

                            ProgressView(value: Double(page.stepNumber), total: Double(OnboardingPages.totalSteps))
                                .tint(OnboardingPalette.accent)
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text(title)
                                .font(.system(size: 30, weight: .light, design: .serif))
                                .foregroundStyle(.white)
                                .fixedSize(horizontal: false, vertical: true)
                            Text(subtitle)
                                .font(.system(size: 13, design: .monospaced))
                                .foregroundStyle(OnboardingPalette.muted)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        if let errorMessage, !errorMessage.isEmpty {
                            AuthErrorBanner(message: errorMessage)
                        }

                        content()

                        Button(action: onPrimaryTap) {
                            HStack(spacing: 10) {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(.circular)
                                        .tint(.white)
                                }
                                Text(primaryTitle)
                                    .font(.system(size: 15, weight: .semibold, design: .monospaced))
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .foregroundStyle((isPrimaryEnabled && !isLoading) ? .white : OnboardingPalette.disabledText)
                            .background(
                                LinearGradient(
                                    colors: (isPrimaryEnabled && !isLoading)
                                        ? [Color(hex: "6366F1"), Color(hex: "4F46E5")]
                                        : [OnboardingPalette.border, OnboardingPalette.border],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .disabled(!isPrimaryEnabled || isLoading)

                        Text("Educational guidance, not financial advice.")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(OnboardingPalette.muted)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .padding(22)
                    .background(OnboardingPalette.surface, in: RoundedRectangle(cornerRadius: 24))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(OnboardingPalette.border, lineWidth: 1)
                    )
                    .frame(maxWidth: 640)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 28)
                }
            }
        }
    }
}

private struct MoneySlider: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title)
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundStyle(OnboardingPalette.muted)
                Spacer()
                Text(currency(value))
                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.white)
            }

            Slider(value: $value, in: range, step: step)
                .tint(tint)
        }
        .padding(14)
        .background(OnboardingPalette.surface, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(OnboardingPalette.border, lineWidth: 1)
        )
    }
}

private struct TogglePill: View {
    let title: String
    let isSelected: Bool
    let tint: Color
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(title)
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundStyle(isSelected ? Color.white : OnboardingPalette.muted)
                .frame(maxWidth: .infinity)
                .frame(height: 42)
                .background(
                    RoundedRectangle(cornerRadius: 11)
                        .fill(isSelected ? tint.opacity(0.2) : OnboardingPalette.surface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 11)
                        .stroke(isSelected ? tint : OnboardingPalette.border, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

private struct RiskSelectionCard: View {
    let title: String
    let subtitle: String
    let isSelected: Bool
    let tint: Color
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Circle()
                    .fill(tint.opacity(isSelected ? 1 : 0.35))
                    .frame(width: 10, height: 10)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .medium, design: .serif))
                        .foregroundStyle(.white)
                    Text(subtitle)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(OnboardingPalette.muted)
                }

                Spacer()
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? tint.opacity(0.14) : OnboardingPalette.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? tint : OnboardingPalette.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct KnowledgeLevelCard: View {
    let title: String
    let description: String
    let level: Double
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(title)
                        .font(.system(size: 16, weight: .medium, design: .serif))
                        .foregroundStyle(.white)
                    Spacer()
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(OnboardingPalette.accent)
                    }
                }

                Text(description)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(OnboardingPalette.muted)

                GeometryReader { geo in
                    RoundedRectangle(cornerRadius: 4)
                        .fill(OnboardingPalette.border)
                        .overlay(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(OnboardingPalette.accent)
                                .frame(width: geo.size.width * level)
                        }
                }
                .frame(height: 8)
            }
            .padding(14)
            .background(OnboardingPalette.surface, in: RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? OnboardingPalette.accent : OnboardingPalette.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct SelectableRowCard: View {
    let title: String
    let subtitle: String
    let isSelected: Bool
    let accent: Color
    let icon: String
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundStyle(isSelected ? accent : OnboardingPalette.muted)
                    .frame(width: 22)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .medium, design: .serif))
                        .foregroundStyle(.white)
                    if !subtitle.isEmpty {
                        Text(subtitle)
                            .font(.system(size: 11, design: .monospaced))
                            .minimumScaleFactor(0.6)
                            .foregroundStyle(OnboardingPalette.muted)
                    }
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(accent)
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? accent.opacity(0.1) : OnboardingPalette.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? accent : OnboardingPalette.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct ChipButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                if !icon.isEmpty {
                    Image(systemName: icon)
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                }
                Text(title)
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
            }
            .lineLimit(1)
            .padding(.horizontal, 12)
            .frame(height: 36)
            .frame(maxWidth: .infinity)
            .foregroundStyle(isSelected ? Color.white : OnboardingPalette.muted)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? OnboardingPalette.accent.opacity(0.18) : OnboardingPalette.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? OnboardingPalette.accent : OnboardingPalette.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct AdaptiveChips: View {
    let items: [String]
    let selection: String
    let onTap: (String) -> Void

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 130), spacing: 8)], spacing: 8) {
            ForEach(items, id: \.self) { item in
                ChipButton(
                    title: item,
                    icon: "",
                    isSelected: selection == item,
                    onTap: { onTap(item) }
                )
            }
        }
    }
}

private struct AuthErrorBanner: View {
    let message: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Color(hex: "F87171"))
            Text(message)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(Color(hex: "FCA5A5"))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(hex: "450A0A").opacity(0.45), in: RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color(hex: "7F1D1D"), lineWidth: 1)
        )
    }
}

private enum OnboardingPalette {
    static let background = Color(hex: "0A0A0F")
    static let surface = Color(hex: "111118")
    static let border = Color(hex: "1F2937")
    static let muted = Color(hex: "6B7280")
    static let accent = Color(hex: "6366F1")
    static let disabledText = Color(hex: "4B5563")
}

private struct OnboardingInputFieldModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(size: 15, design: .serif))
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .frame(height: 50)
            .background(OnboardingPalette.background.opacity(0.8), in: RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(OnboardingPalette.border, lineWidth: 1)
            )
    }
}

private struct OnboardingTextAreaModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(size: 15, design: .serif))
            .foregroundStyle(.white)
            .padding(14)
            .background(OnboardingPalette.background.opacity(0.8), in: RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(OnboardingPalette.border, lineWidth: 1)
            )
    }
}

private extension View {
    func onboardingInputStyle() -> some View {
        modifier(OnboardingInputFieldModifier())
    }

    func onboardingTextAreaStyle() -> some View {
        modifier(OnboardingTextAreaModifier())
    }

    func onboardingFieldLabelStyle() -> some View {
        font(.system(size: 11, weight: .semibold, design: .monospaced))
            .foregroundStyle(OnboardingPalette.muted)
    }
}

private func currency(_ value: Double) -> String {
    formatCurrency(value)
}
