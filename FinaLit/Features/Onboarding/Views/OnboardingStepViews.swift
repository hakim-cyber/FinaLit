import SwiftUI

// MARK: - Step 1

struct OnboardingPersonalInfoView: View {
    @Environment(OnboardingViewModel.self) private var viewModel
    @Environment(Coordinator<OnboardingPages>.self) private var coordinator

    private let countries = [
        "United States", "Canada", "United Kingdom", "Germany", "India", "Australia"
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
                        .font(.subheadline.weight(.medium))
                    TextField("Your name", text: $viewModel.name)
                        .textInputAutocapitalization(.words)
                        .padding(.horizontal, 14)
                        .frame(height: 50)
                        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }

                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Age")
                            .font(.subheadline.weight(.medium))
                        Spacer()
                        Text("\(Int(viewModel.age.rounded()))")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: $viewModel.age, in: 13...70, step: 1)
                        .tint(.blue)
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Country")
                        .font(.subheadline.weight(.medium))

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
                        .padding(.horizontal, 14)
                        .frame(height: 50)
                        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
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
                        subtitle: status == viewModel.employmentStatus ? "Selected" : "",
                        isSelected: viewModel.employmentStatus == status,
                        accent: .blue,
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
                        .font(.subheadline.weight(.medium))

                    HStack(spacing: 10) {
                        TogglePill(
                            title: "Stable",
                            isSelected: viewModel.incomeStability == .stable,
                            tint: .blue
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
                    tint: .blue
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
                        .font(.subheadline.weight(.medium))

                    HStack {
                        Text("Months covered")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Stepper(value: $viewModel.emergencyFundMonths, in: 0...24) {
                            Text("\(viewModel.emergencyFundMonths) months")
                                .font(.subheadline.weight(.semibold))
                        }
                    }
                    .padding(14)
                    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
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
        @Bindable var viewModel = viewModel

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
                        viewModel.hasDebt = false
                        viewModel.debtAmount = 0
                        viewModel.clearError()
                    }

                    TogglePill(title: "I have debt", isSelected: viewModel.hasDebt, tint: .red) {
                        viewModel.hasDebt = true
                        viewModel.clearError()
                    }
                }

                if viewModel.hasDebt {
                    MoneySlider(
                        title: "Total debt",
                        value: $viewModel.debtAmount,
                        range: 0...250000,
                        step: 100,
                        tint: .red
                    )
                }
            }
        }
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
                    .font(.subheadline.weight(.medium))

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
                        .font(.subheadline.weight(.medium))

                    HStack(spacing: 10) {
                        TogglePill(title: "Yes", isSelected: viewModel.interestedInInvesting, tint: .blue) {
                            viewModel.interestedInInvesting = true
                            viewModel.clearError()
                        }
                        TogglePill(title: "Not now", isSelected: !viewModel.interestedInInvesting, tint: .gray) {
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
        "Build a $1,000 emergency fund",
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
                    .padding(14)
                    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
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
                    .padding(14)
                    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
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
                    .font(.caption)
                    .foregroundStyle(.secondary)

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
                    .font(.caption)
                    .foregroundStyle(.secondary)

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
                        .padding(.horizontal, 14)
                        .frame(height: 50)
                        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
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
        ScrollView {
            VStack {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(spacing: 14) {
                        HStack {
                            if page.stepNumber > 1 {
                                Button {
                                    coordinator.pop()
                                } label: {
                                    Image(systemName: "chevron.left")
                                        .font(.headline.weight(.semibold))
                                        .frame(width: 34, height: 34)
                                        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                                }
                                .buttonStyle(.plain)
                            }

                            Spacer()

                            Text("Step \(page.stepNumber) of \(OnboardingPages.totalSteps)")
                                .font(.footnote.weight(.medium))
                                .foregroundStyle(.secondary)
                        }

                        ProgressView(value: Double(page.stepNumber), total: Double(OnboardingPages.totalSteps))
                            .tint(.blue)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text(title)
                            .font(.title2.weight(.bold))
                            .fixedSize(horizontal: false, vertical: true)
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
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
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .foregroundStyle(.white)
                        .background(Color.black, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .disabled(!isPrimaryEnabled || isLoading)
                    .opacity((isPrimaryEnabled && !isLoading) ? 1.0 : 0.45)

                    Text("Educational guidance, not financial advice.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .padding(22)
                .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color(.systemGray5), lineWidth: 1)
                )
                .frame(maxWidth: 640)
                .padding(.horizontal, 20)
                .padding(.vertical, 28)
            }
        }
        .background(
            LinearGradient(
                colors: [Color(.systemGroupedBackground), Color(.secondarySystemBackground)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
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
                    .font(.subheadline.weight(.medium))
                Spacer()
                Text(currency(value))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            Slider(value: $value, in: range, step: step)
                .tint(tint)
        }
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
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(isSelected ? Color.white : Color.primary)
                .frame(maxWidth: .infinity)
                .frame(height: 42)
                .background(
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .fill(isSelected ? tint : Color(.secondarySystemBackground))
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
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isSelected ? tint.opacity(0.14) : Color(.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isSelected ? tint : Color(.systemGray5), lineWidth: 1)
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
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.blue)
                    }
                }

                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                GeometryReader { geo in
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(Color(.systemGray5))
                        .overlay(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .fill(Color.blue)
                                .frame(width: geo.size.width * level)
                        }
                }
                .frame(height: 8)
            }
            .padding(14)
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isSelected ? Color.blue : Color(.systemGray5), lineWidth: 1)
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
                    .foregroundStyle(isSelected ? accent : .secondary)
                    .frame(width: 22)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    if !subtitle.isEmpty {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
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
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isSelected ? accent.opacity(0.1) : Color(.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isSelected ? accent : Color(.systemGray5), lineWidth: 1)
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
                        .font(.caption)
                }
                Text(title)
                    .font(.caption.weight(.semibold))
            }
            .lineLimit(1)
            .padding(.horizontal, 12)
            .frame(height: 36)
            .frame(maxWidth: .infinity)
            .foregroundStyle(isSelected ? Color.white : Color.primary)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isSelected ? Color.blue : Color(.secondarySystemBackground))
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
                .foregroundStyle(.red)
            Text(message)
                .font(.footnote)
                .foregroundStyle(.red)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

private func currency(_ value: Double) -> String {
    onboardingCurrencyFormatter.string(from: NSNumber(value: value)) ?? "$\(Int(value))"
}

private let onboardingCurrencyFormatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.maximumFractionDigits = 0
    formatter.locale = .current
    return formatter
}()
