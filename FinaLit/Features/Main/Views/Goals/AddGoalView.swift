//
//  AddGoalView.swift
//  FinaLit
//

import SwiftUI

struct AddGoalView: View {
    @Environment(MainViewModel.self) private var mainVM
    @Environment(Coordinator<MainPages>.self) private var coordinator
    @State private var title: String = ""
    @State private var targetAmount: String = ""
    @State private var hasDeadline: Bool = false
    @State private var deadline: Date = Calendar.current.date(byAdding: .month, value: 6, to: Date()) ?? Date()
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
            Text("Templates")
                .appFieldLabelStyle()

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(goalTemplates) { template in
                        Button {
                            applyTemplate(template)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(template.title)
                                    .font(AppTheme.Typography.bodySemibold)
                                    .foregroundStyle(AppTheme.textPrimary)
                                    .lineLimit(1)
                                Text("\(formatCurrency(template.targetAmount)) - \(template.hint)")
                                    .font(AppTheme.Typography.detail)
                                    .foregroundStyle(AppTheme.textSecondary)
                            }
                            .frame(width: 165, alignment: .leading)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(AppTheme.surfacePrimary)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(
                                        selectedTemplateID == template.id ? AppTheme.accent : AppTheme.separator,
                                        lineWidth: 1
                                    )
                            )
                        }
                        .buttonStyle(.plain)
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
                    .foregroundStyle(AppTheme.success)
                Text("Goal created")
                    .font(AppTheme.Typography.bodySemibold)
                    .foregroundStyle(AppTheme.textPrimary)
            }

            Text("\"\(createdGoalTitle)\" is now active.")
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.textSecondary)

            HStack(spacing: 10) {
                Button {
                    openCreatedGoal()
                } label: {
                    Text("View Goal")
                        .padding(.horizontal, 14)
                }
                .buttonStyle(AppFilledButtonStyle(tone: .accent, compact: true, fillsWidth: false))

                Button {
                    coordinator.pop()
                } label: {
                    Text("Done")
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .foregroundStyle(AppTheme.textSecondary)
                        .background(AppTheme.surfaceSecondary)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .appSurface(.primary, padding: 14, cornerRadius: AppTheme.CornerRadius.large)
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
        ZStack {
            AppTheme.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    templatesSection

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Goal name")
                            .appFieldLabelStyle()
                        TextField("e.g. Emergency Fund", text: $title)
                            .appInputStyle()
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Target amount")
                            .appFieldLabelStyle()
                        HStack(spacing: 4) {
                            Text(AppRegion.currencySymbol)
                                .font(.system(size: 30, weight: .semibold, design: .rounded))
                                .foregroundStyle(AppTheme.textSecondary)
                            TextField("5,000", text: $targetAmount)
                                .font(.system(size: 32, weight: .semibold, design: .rounded))
                                .foregroundStyle(AppTheme.textPrimary)
                                .keyboardType(.decimalPad)
                                .tint(AppTheme.accent)
                        }
                        Divider().background(AppTheme.separator)
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Set deadline")
                                .appFieldLabelStyle()
                            Spacer()
                            Toggle("", isOn: $hasDeadline)
                                .tint(AppTheme.accent)
                        }
                        if hasDeadline {
                            DatePicker("", selection: $deadline, in: Date()..., displayedComponents: .date)
                                .datePickerStyle(.compact)
                                .tint(AppTheme.accent)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(AppTheme.surfacePrimary, in: RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                                        .stroke(AppTheme.separator, lineWidth: 1)
                                )
                                .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }

                    Spacer(minLength: 80)
                }
                .padding(.horizontal, AppTheme.Spacing.screen)
                .padding(.top, 20)
            }

            if showCreatedGoalToast {
                goalCreatedToast
                    .padding(.horizontal, AppTheme.Spacing.screen)
                    .padding(.bottom, 120)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .safeAreaInset(edge: .bottom) {
            Button {
                createGoal()
            } label: {
                HStack(spacing: 10) {
                    Text("Create Goal")
                    if mainVM.isSubmitting {
                        ProgressView()
                            .tint(AppTheme.inverseText)
                            .scaleEffect(0.8)
                    }
                }
            }
            .buttonStyle(AppFilledButtonStyle(tone: .accent))
            .disabled(isCreateDisabled)
            .padding(.horizontal, AppTheme.Spacing.screen)
            .padding(.top, 8)
            .padding(.bottom, 8)
            .background(AppTheme.background.opacity(0.94))
        }
        .navigationTitle("New Goal")
        .navigationBarTitleDisplayMode(.inline)
    }
}
