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
                                .font(.system(size: 11, weight: .semibold, design: .monospaced))
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
                                .font(.system(size: 11, weight: .semibold, design: .monospaced))
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
                                .font(.system(size: 14, design: .monospaced))
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

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(goal.title)
                        .font(.system(size: 17, weight: .medium, design: .serif))
                        .foregroundStyle(.white)
                    if let deadline = goal.deadline {
                        Text("Due \(deadline.formatted(date: .abbreviated, time: .omitted))")
                            .font(.system(size: 11, design: .monospaced))
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
                        .font(.system(size: 18, weight: .semibold, design: .monospaced))
                        .foregroundStyle(Color(hex: "6366F1"))
                }
            }

            // Amount row
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("€\(formatAmount(goal.currentAmount))")
                        .font(.system(size: 20, weight: .light, design: .serif))
                        .foregroundStyle(.white)
                    Text("saved")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(Color(hex: "4B5563"))
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("€\(formatAmount(goal.targetAmount))")
                        .font(.system(size: 16, design: .monospaced))
                        .foregroundStyle(Color(hex: "6B7280"))
                    Text("target")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(Color(hex: "4B5563"))
                }
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
                .font(.system(size: 18, design: .serif))
                .foregroundStyle(.white)
            Text("Set a financial goal to track your progress.")
                .font(.system(size: 13, design: .monospaced))
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

    private var isValid: Bool {
        !title.isEmpty && Double(targetAmount) != nil && (Double(targetAmount) ?? 0) > 0
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color(hex: "0A0A0F").ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {

                    VStack(alignment: .leading, spacing: 8) {
                        Text("GOAL NAME")
                            .font(.system(size: 10, weight: .semibold, design: .monospaced))
                            .foregroundStyle(Color(hex: "4B5563"))
                        TextField("e.g. Emergency Fund", text: $title)
                            .font(.system(size: 18, design: .serif))
                            .foregroundStyle(.white)
                            .padding(16)
                            .background(Color(hex: "111118"))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "1F2937"), lineWidth: 1))
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("TARGET AMOUNT")
                            .font(.system(size: 10, weight: .semibold, design: .monospaced))
                            .foregroundStyle(Color(hex: "4B5563"))
                        HStack(spacing: 4) {
                            Text("€")
                                .font(.system(size: 32, weight: .light, design: .serif))
                                .foregroundStyle(Color(hex: "374151"))
                            TextField("5,000", text: $targetAmount)
                                .font(.system(size: 32, weight: .light, design: .serif))
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
                                .font(.system(size: 10, weight: .semibold, design: .monospaced))
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

                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }

            // Save button
            VStack(spacing: 0) {
                LinearGradient(
                    colors: [Color(hex: "0A0A0F").opacity(0), Color(hex: "0A0A0F")],
                    startPoint: .top, endPoint: .bottom
                )
                .frame(height: 30)
                Button {
                    Task {
                        let saved = await mainVM.addGoal(
                            title:        title,
                            targetAmount: Double(targetAmount) ?? 0,
                            deadline:     hasDeadline ? deadline : nil
                        )
                        if saved { coordinator.pop() }
                    }
                } label: {
                    HStack {
                        Text("Create Goal")
                            .font(.system(size: 16, design: .monospaced))
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
                .disabled(!isValid || mainVM.isSubmitting)
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
                                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                                .foregroundStyle(Color(hex: "4B5563"))
                                .padding(.horizontal, 20)

                            HStack(spacing: 12) {
                                HStack(spacing: 4) {
                                    Text("€")
                                        .font(.system(size: 16, design: .monospaced))
                                        .foregroundStyle(Color(hex: "4B5563"))
                                    TextField("Contribution", text: $newAmount)
                                        .font(.system(size: 16, design: .monospaced))
                                        .foregroundStyle(.white)
                                        .keyboardType(.decimalPad)
                                        .tint(Color(hex: "6366F1"))
                                }
                                .padding(14)
                                .background(Color(hex: "111118"))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "1F2937"), lineWidth: 1))

                                Button("Add") {
                                    if let amount = Double(newAmount) {
                                        Task {
                                            let saved = await mainVM.contributeToGoal(goal: goal, amount: amount)
                                            if saved { newAmount = "" }
                                        }
                                    }
                                }
                                .font(.system(size: 14, design: .monospaced))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 14)
                                .background(Color(hex: "6366F1"))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .disabled((Double(newAmount) ?? 0) <= 0)
                            }
                            .padding(.horizontal, 20)
                        }

                        // ── Remaining ──────────────────────────────────────
                        let remaining = goal.targetAmount - goal.currentAmount
                        if remaining > 0 {
                            HStack {
                                Text("Still needed:")
                                    .font(.system(size: 13, design: .monospaced))
                                    .foregroundStyle(Color(hex: "4B5563"))
                                Spacer()
                                Text("€\(formatAmount(remaining))")
                                    .font(.system(size: 16, weight: .semibold, design: .monospaced))
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
                            .font(.system(size: 14, design: .monospaced))
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
