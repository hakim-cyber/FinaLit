//
//  ReflectionView.swift
//  FinaLit
//

import SwiftUI

struct ReflectionView: View {
    let weekID: String
    let weekTitle: String

    @Environment(LearnViewModel.self) private var learnVM
    @Environment(Coordinator<LearnPages>.self) private var coordinator
    @State private var content: String = ""
    @FocusState private var isFocused: Bool

    private let minLength = 100

    private var canSubmit: Bool {
        content.trimmingCharacters(in: .whitespacesAndNewlines).count >= minLength
    }

    private var charCount: Int {
        content.trimmingCharacters(in: .whitespacesAndNewlines).count
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            AppTheme.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("📝")
                            .font(.system(size: 36))
                        Text(L10n.Common.weekReflection)
                            .font(.system(size: 30, weight: .medium))
                            .foregroundStyle(AppTheme.textPrimary)
                        Text(weekTitle)
                            .font(.system(size: 14))
                            .foregroundStyle(AppTheme.accent)
                    }

                    VStack(spacing: 10) {
                        ReflectionPrompt(number: "01", text: "What concept stuck with you most this week?")
                        ReflectionPrompt(number: "02", text: "Did you change any financial decision based on what you learned?")
                        ReflectionPrompt(number: "03", text: "What will you do differently going forward?")
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text(L10n.Common.yourReflection)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(AppTheme.textSecondary)

                        ZStack(alignment: .topLeading) {
                            if content.isEmpty {
                                Text("Write your thoughts here... (min \(minLength) characters)")
                                    .font(.system(size: 15))
                                    .foregroundStyle(AppTheme.textTertiary)
                                    .padding(.top, 14)
                                    .padding(.leading, 16)
                                    .allowsHitTesting(false)
                            }
                            TextEditor(text: $content)
                                .font(.system(size: 15))
                                .foregroundStyle(AppTheme.textPrimary)
                                .scrollContentBackground(.hidden)
                                .background(Color.clear)
                                .padding(12)
                                .frame(minHeight: 180)
                                .focused($isFocused)
                        }
                        .background(AppTheme.surfacePrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(
                                    isFocused ? AppTheme.accent.opacity(0.5) : AppTheme.separator,
                                    lineWidth: 1.5
                                )
                        )

                        HStack {
                            if !canSubmit && charCount > 0 {
                                Text("\(minLength - charCount) more characters needed")
                                    .font(.system(size: 11))
                                    .foregroundStyle(AppTheme.danger)
                            } else if canSubmit {
                                Text(L10n.Common.readyToSubmit)
                                    .font(.system(size: 11))
                                    .foregroundStyle(AppTheme.success)
                            }
                            Spacer()
                            Text("\(charCount)")
                                .font(.system(size: 11))
                                .foregroundStyle(canSubmit ? AppTheme.success : AppTheme.textSecondary)
                        }
                    }

                    Spacer(minLength: 120)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
            }

            VStack(spacing: 0) {
                LinearGradient(
                    colors: [AppTheme.background.opacity(0), AppTheme.background],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 30)

                Button {
                    isFocused = false
                    Task {
                        let success = await learnVM.submitReflection(
                            weekID: weekID,
                            weekTitle: weekTitle,
                            content: content
                        )
                        if success {
                            coordinator.popToRoot()
                        }
                    }
                } label: {
                    HStack {
                        Text(L10n.Common.submitReflection)
                            .font(.system(size: 16))
                        if learnVM.isSubmitting {
                            ProgressView()
                                .tint(.white)
                                .scaleEffect(0.8)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        canSubmit
                            ? LinearGradient(
                                colors: [AppTheme.success, AppTheme.success],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                            : LinearGradient(
                                colors: [AppTheme.separator, AppTheme.separator],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                    )
                    .foregroundStyle(canSubmit ? .white : AppTheme.textTertiary)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
                .background(AppTheme.background)
                .disabled(!canSubmit || learnVM.isSubmitting)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .alert(L10n.Admin.error, isPresented: isShowingErrorAlert) {
            Button(L10n.Common.tryAgain) {
                Task {
                    let success = await learnVM.submitReflection(
                        weekID: weekID,
                        weekTitle: weekTitle,
                        content: content
                    )
                    if success {
                        coordinator.popToRoot()
                    }
                }
            }
            Button(L10n.Auth.ok) { learnVM.clearError() }
        } message: {
            Text(learnVM.errorMessage ?? "")
        }
    }

    private var isShowingErrorAlert: Binding<Bool> {
        Binding(
            get: { learnVM.errorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    learnVM.clearError()
                }
            }
        )
    }
}
