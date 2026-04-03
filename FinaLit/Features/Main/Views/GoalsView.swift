//
//  GoalsView.swift
//  FinaLit
//
//  Created by aplle on 2/20/26.
//


// GoalsView.swift
// Features/Main/Views/

import SwiftUI

struct GoalsView: View {
    @Environment(MainViewModel.self)          private var mainVM
    @Environment(Coordinator<MainPages>.self) private var coordinator

    var body: some View {
        ZStack {
            Color(hex: "0A0A0F").ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {

                    // ── Active goals ───────────────────────────────────────
                    if mainVM.activeGoals.isEmpty {
                        EmptyGoalsCard()
                            .padding(.horizontal, 20)
                            .padding(.top, 8)
                    } else {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("ACTIVE GOALS")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(Color(hex: "4B5563"))
                                .padding(.horizontal, 20)

                            ForEach(mainVM.activeGoals) { goal in
                                GoalCard(goal: goal)
                                    .padding(.horizontal, 20)
                                    .onTapGesture {
                                        coordinator.push(.goalDetail(goal.id ?? ""))
                                    }
                            }
                        }
                    }

                    // ── Completed goals ────────────────────────────────────
                    if !mainVM.completedGoals.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("COMPLETED")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(Color(hex: "4B5563"))
                                .padding(.horizontal, 20)

                            ForEach(mainVM.completedGoals) { goal in
                                GoalCard(goal: goal, isCompleted: true)
                                    .padding(.horizontal, 20)
                            }
                        }
                    }

                    Spacer(minLength: 100)
                }
                .padding(.top, 16)
            }

            // ── FAB ────────────────────────────────────────────────────────
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button {
                        coordinator.push(.addGoal)
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "plus")
                                .font(.system(size: 14, weight: .semibold))
                            Text("New Goal")
                                .font(.system(size: 14))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                colors: [Color(hex: "6366F1"), Color(hex: "4F46E5")],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .clipShape(Capsule())
                        .shadow(color: Color(hex: "6366F1").opacity(0.4), radius: 10, y: 4)
                    }
                    .padding(.trailing, 24)
                    .padding(.bottom, 16)
                }
            }
        }
        .navigationTitle("Goals")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct GoalCard: View {
    let goal:        FinancialGoal
    var isCompleted: Bool = false

    private var remainingAmount: Double {
        max(goal.targetAmount - goal.currentAmount, 0)
    }

    private var monthsUntilDeadline: Int? {
        guard let deadline = goal.deadline else { return nil }
        let calendar = Calendar.current
        let fromDate = calendar.startOfDay(for: Date())
        let toDate = calendar.startOfDay(for: deadline)
        return calendar.dateComponents([.month], from: fromDate, to: toDate).month
    }

    private var monthlyPaceText: String? {
        guard !isCompleted, remainingAmount > 0, let monthsUntilDeadline else { return nil }
        guard monthsUntilDeadline >= 0 else { return "Deadline passed" }

        let monthWindow = max(monthsUntilDeadline, 1)
        let neededPerMonth = remainingAmount / Double(monthWindow)
        return "Need \(formatCurrency(neededPerMonth))/month"
    }

    private var monthlyPaceColor: Color {
        guard let monthsUntilDeadline else { return Color(hex: "4B5563") }
        return monthsUntilDeadline < 0 ? Color(hex: "F87171") : Color(hex: "10B981")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(goal.title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)
                    if let deadline = goal.deadline {
                        Text("Due \(deadline.formatted(date: .abbreviated, time: .omitted))")
                            .font(.system(size: 11))
                            .foregroundStyle(Color(hex: "4B5563"))
                    }
                }
                Spacer()
                if isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color(hex: "10B981"))
                        .font(.system(size: 20))
                } else {
                    Text("\(String(format: "%.0f", goal.progressPercentage))%")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Color(hex: "6366F1"))
                }
            }

            // Amount row
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(formatCurrency(goal.currentAmount))
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(.white)
                    Text("saved")
                        .font(.system(size: 10))
                        .foregroundStyle(Color(hex: "4B5563"))
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(formatCurrency(goal.targetAmount))
                        .font(.system(size: 16))
                        .foregroundStyle(Color(hex: "6B7280"))
                    Text("target")
                        .font(.system(size: 10))
                        .foregroundStyle(Color(hex: "4B5563"))
                }
            }

            if let monthlyPaceText {
                HStack(spacing: 6) {
                    Image(systemName: "speedometer")
                        .font(.system(size: 10))
                    Text(monthlyPaceText)
                        .font(.system(size: 10, weight: .semibold))
                }
                .foregroundStyle(monthlyPaceColor)
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(hex: "1F2937"))
                        .frame(height: 8)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            isCompleted
                                ? LinearGradient(colors: [Color(hex: "10B981"), Color(hex: "10B981")],
                                                 startPoint: .leading, endPoint: .trailing)
                                : LinearGradient(colors: [Color(hex: "6366F1"), Color(hex: "10B981")],
                                                 startPoint: .leading, endPoint: .trailing)
                        )
                        .frame(
                            width: geo.size.width * CGFloat(goal.progressPercentage / 100),
                            height: 8
                        )
                        .animation(.easeInOut(duration: 0.5), value: goal.progressPercentage)
                }
            }
            .frame(height: 8)
        }
        .padding(18)
        .background(Color(hex: "111118"))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    isCompleted ? Color(hex: "10B981").opacity(0.3) : Color(hex: "1F2937"),
                    lineWidth: 1
                )
        )
        .opacity(isCompleted ? 0.6 : 1)
    }
}

struct EmptyGoalsCard: View {
    var body: some View {
        VStack(spacing: 14) {
            Text("🎯")
                .font(.system(size: 40))
            Text("No goals yet")
                .font(.system(size: 18))
                .foregroundStyle(.white)
            Text("Set a financial goal to track your progress.")
                .font(.system(size: 13))
                .foregroundStyle(Color(hex: "4B5563"))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .background(Color(hex: "111118"))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(hex: "1F2937"), lineWidth: 1))
    }
}

// MARK: - Add Goal View
struct AddGoalView: View {
    @Environment(MainViewModel.self)          private var mainVM
    @Environment(Coordinator<MainPages>.self) private var coordinator
    @State private var title:         String = ""
    @State private var targetAmount:  String = ""
    @State private var hasDeadline:   Bool   = false
    @State private var deadline:      Date   = Calendar.current.date(byAdding: .month, value: 6, to: Date()) ?? Date()
    @State private var selectedTemplateID: String?
    @State private var createdGoalID: String?
    @State private var createdGoalTitle: String = ""
    @State private var showCreatedGoalToast = false

    private struct GoalTemplatePreset: Identifiable {
        let id: String
        let title: String
        let targetAmount: Double
        let deadlineMonths: Int
        let hint: String
    }

    private let goalTemplates: [GoalTemplatePreset] = [
        .init(id: "emergency_fund", title: "Emergency Fund", targetAmount: 3000, deadlineMonths: 6, hint: "6 months"),
        .init(id: "vacation", title: "Vacation", targetAmount: 1500, deadlineMonths: 4, hint: "4 months"),
        .init(id: "new_laptop", title: "New Laptop", targetAmount: 2200, deadlineMonths: 8, hint: "8 months"),
        .init(id: "car_down_payment", title: "Car Down Payment", targetAmount: 5000, deadlineMonths: 12, hint: "12 months")
    ]

    private var parsedTargetAmount: Double? {
        parseMonetaryInput(targetAmount)
    }

    private var trimmedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isValid: Bool {
        !trimmedTitle.isEmpty &&
        (parsedTargetAmount ?? 0) > 0
    }

    private var isCreateDisabled: Bool {
        !isValid || mainVM.isSubmitting || showCreatedGoalToast
    }

    private var templatesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("TEMPLATES")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(Color(hex: "4B5563"))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(goalTemplates) { template in
                        Button {
                            applyTemplate(template)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(template.title)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(.white)
                                    .lineLimit(1)
                                Text("\(formatCurrency(template.targetAmount)) - \(template.hint)")
                                    .font(.system(size: 10))
                                    .foregroundStyle(Color(hex: "6B7280"))
                            }
                            .frame(width: 165, alignment: .leading)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(Color(hex: "111118"))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(
                                        selectedTemplateID == template.id ? Color(hex: "6366F1") : Color(hex: "1F2937"),
                                        lineWidth: 1
                                    )
                            )
                        }
                    }
                }
                .padding(.vertical, 1)
            }
        }
    }

    private var goalCreatedToast: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Color(hex: "10B981"))
                Text("Goal created")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
            }

            Text("\"\(createdGoalTitle)\" is now active.")
                .font(.system(size: 12))
                .foregroundStyle(Color(hex: "9CA3AF"))

            HStack(spacing: 10) {
                Button {
                    openCreatedGoal()
                } label: {
                    Text("View Goal")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color(hex: "6366F1"))
                        .clipShape(Capsule())
                }

                Button {
                    coordinator.pop()
                } label: {
                    Text("Done")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color(hex: "9CA3AF"))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color(hex: "1F2937"))
                        .clipShape(Capsule())
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(hex: "111118"))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(hex: "1F2937"), lineWidth: 1))
    }

    private func applyTemplate(_ template: GoalTemplatePreset) {
        selectedTemplateID = template.id
        title = template.title
        targetAmount = formatAmount(template.targetAmount)
        hasDeadline = true
        deadline = Calendar.current.date(byAdding: .month, value: template.deadlineMonths, to: Date()) ?? Date()
    }

    private func createGoal() {
        Task {
            let createdID = await mainVM.addGoal(
                title: trimmedTitle,
                targetAmount: parsedTargetAmount ?? 0,
                deadline: hasDeadline ? deadline : nil
            )

            guard let createdID else { return }

            createdGoalID = createdID
            createdGoalTitle = trimmedTitle
            KeyboardUX.dismiss()
            withAnimation(.easeInOut(duration: 0.2)) {
                showCreatedGoalToast = true
            }
        }
    }

    private func openCreatedGoal() {
        guard let createdGoalID else { return }
        withAnimation(.easeInOut(duration: 0.2)) {
            showCreatedGoalToast = false
        }
        coordinator.pop()
        coordinator.push(.goalDetail(createdGoalID))
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color(hex: "0A0A0F").ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    templatesSection

                    VStack(alignment: .leading, spacing: 8) {
                        Text("GOAL NAME")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(Color(hex: "4B5563"))
                        TextField("e.g. Emergency Fund", text: $title)
                            .font(.system(size: 18))
                            .foregroundStyle(.white)
                            .padding(16)
                            .background(Color(hex: "111118"))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "1F2937"), lineWidth: 1))
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("TARGET AMOUNT")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(Color(hex: "4B5563"))
                        HStack(spacing: 4) {
                            Text(AppRegion.currencySymbol)
                                .font(.system(size: 32, weight: .medium))
                                .foregroundStyle(Color(hex: "374151"))
                            TextField("5,000", text: $targetAmount)
                                .font(.system(size: 32, weight: .medium))
                                .foregroundStyle(.white)
                                .keyboardType(.decimalPad)
                                .tint(Color(hex: "6366F1"))
                        }
                        Divider().background(Color(hex: "1F2937"))
                    }

                    // Deadline toggle
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("SET DEADLINE")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(Color(hex: "4B5563"))
                            Spacer()
                            Toggle("", isOn: $hasDeadline)
                                .tint(Color(hex: "6366F1"))
                        }
                        if hasDeadline {
                            DatePicker("", selection: $deadline, in: Date()..., displayedComponents: .date)
                                .datePickerStyle(.compact)
                                .tint(Color(hex: "6366F1"))
                                .colorScheme(.dark)
                                .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }

                    Spacer(minLength: 160)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }

            if showCreatedGoalToast {
                goalCreatedToast
                    .padding(.horizontal, 20)
                    .padding(.bottom, 120)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            // Save button
            VStack(spacing: 0) {
                LinearGradient(
                    colors: [Color(hex: "0A0A0F").opacity(0), Color(hex: "0A0A0F")],
                    startPoint: .top, endPoint: .bottom
                )
                .frame(height: 30)
                Button {
                    createGoal()
                } label: {
                    HStack {
                        Text("Create Goal")
                            .font(.system(size: 16))
                        if mainVM.isSubmitting {
                            ProgressView().tint(.white).scaleEffect(0.8)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        isValid
                            ? LinearGradient(colors: [Color(hex: "6366F1"), Color(hex: "4F46E5")],
                                             startPoint: .leading, endPoint: .trailing)
                            : LinearGradient(colors: [Color(hex: "1F2937"), Color(hex: "1F2937")],
                                             startPoint: .leading, endPoint: .trailing)
                    )
                    .foregroundStyle(isValid ? .white : Color(hex: "374151"))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .disabled(isCreateDisabled)
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
                .background(Color(hex: "0A0A0F"))
            }
        }
        .navigationTitle("New Goal")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Goal Detail View
struct GoalDetailView: View {
    let goalID: String
    @Environment(MainViewModel.self)          private var mainVM
    @Environment(Coordinator<MainPages>.self) private var coordinator
    @State private var newAmount: String = ""
    @State private var showDeleteAlert = false

    private var parsedContributionAmount: Double? {
        parseMonetaryInput(newAmount)
    }

    private var goal: FinancialGoal? {
        mainVM.goals.first { $0.id == goalID }
    }

    var body: some View {
        ZStack {
            Color(hex: "0A0A0F").ignoresSafeArea()

            if let goal {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {

                        GoalCard(goal: goal)
                            .padding(.horizontal, 20)
                            .padding(.top, 8)

                        // ── Add contribution ───────────────────────────────
                        VStack(alignment: .leading, spacing: 12) {
                            Text("ADD CONTRIBUTION")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(Color(hex: "4B5563"))
                                .padding(.horizontal, 20)

                            HStack(spacing: 12) {
                                HStack(spacing: 4) {
                                    Text(AppRegion.currencySymbol)
                                        .font(.system(size: 16))
                                        .foregroundStyle(Color(hex: "4B5563"))
                                    TextField("Contribution", text: $newAmount)
                                        .font(.system(size: 16))
                                        .foregroundStyle(.white)
                                        .keyboardType(.decimalPad)
                                        .tint(Color(hex: "6366F1"))
                                }
                                .padding(14)
                                .background(Color(hex: "111118"))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "1F2937"), lineWidth: 1))

                                Button("Add") {
                                    if let amount = parsedContributionAmount {
                                        Task {
                                            let saved = await mainVM.contributeToGoal(goal: goal, amount: amount)
                                            if saved { newAmount = "" }
                                        }
                                    }
                                }
                                .font(.system(size: 14))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 14)
                                .background(Color(hex: "6366F1"))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .disabled((parsedContributionAmount ?? 0) <= 0)
                            }
                            .padding(.horizontal, 20)
                        }

                        // ── Remaining ──────────────────────────────────────
                        let remaining = goal.targetAmount - goal.currentAmount
                        if remaining > 0 {
                            HStack {
                                Text("Still needed:")
                                    .font(.system(size: 13))
                                    .foregroundStyle(Color(hex: "4B5563"))
                                Spacer()
                                Text(formatCurrency(remaining))
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(Color(hex: "6366F1"))
                            }
                            .padding(.horizontal, 32)
                        }

                        // ── Delete ─────────────────────────────────────────
                        Button {
                            showDeleteAlert = true
                        } label: {
                            HStack {
                                Image(systemName: "trash")
                                Text("Delete Goal")
                            }
                            .font(.system(size: 14))
                            .foregroundStyle(Color(hex: "F87171"))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color(hex: "F87171").opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                    }
                }
            }
        }
        .onAppear {
            if goal != nil { newAmount = "" }
        }
        .navigationTitle("Goal")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Delete Goal?", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) {
                Task {
                    if let goal { await mainVM.deleteGoal(goal) }
                    coordinator.pop()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This cannot be undone.")
        }
    }
}
