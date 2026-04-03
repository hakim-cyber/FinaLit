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
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color(hex: "1F2937"), lineWidth: 1)
        )
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
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(hex: "1F2937"), lineWidth: 1)
                            )
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

            VStack(spacing: 0) {
                LinearGradient(
                    colors: [Color(hex: "0A0A0F").opacity(0), Color(hex: "0A0A0F")],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 30)

                Button {
                    createGoal()
                } label: {
                    HStack {
                        Text("Create Goal")
                            .font(.system(size: 16))
                        if mainVM.isSubmitting {
                            ProgressView()
                                .tint(.white)
                                .scaleEffect(0.8)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        isValid
                            ? LinearGradient(
                                colors: [Color(hex: "6366F1"), Color(hex: "4F46E5")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                            : LinearGradient(
                                colors: [Color(hex: "1F2937"), Color(hex: "1F2937")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
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
