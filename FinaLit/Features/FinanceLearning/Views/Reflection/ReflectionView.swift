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
            Color(hex: "0A0A0F").ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("📝")
                            .font(.system(size: 36))
                        Text("Week Reflection")
                            .font(.system(size: 30, weight: .medium))
                            .foregroundStyle(.white)
                        Text(weekTitle)
                            .font(.system(size: 14))
                            .foregroundStyle(Color(hex: "6366F1"))
                    }

                    VStack(spacing: 10) {
                        ReflectionPrompt(number: "01", text: "What concept stuck with you most this week?")
                        ReflectionPrompt(number: "02", text: "Did you change any financial decision based on what you learned?")
                        ReflectionPrompt(number: "03", text: "What will you do differently going forward?")
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("YOUR REFLECTION")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(Color(hex: "4B5563"))

                        ZStack(alignment: .topLeading) {
                            if content.isEmpty {
                                Text("Write your thoughts here... (min \(minLength) characters)")
                                    .font(.system(size: 15))
                                    .foregroundStyle(Color(hex: "374151"))
                                    .padding(.top, 14)
                                    .padding(.leading, 16)
                                    .allowsHitTesting(false)
                            }
                            TextEditor(text: $content)
                                .font(.system(size: 15))
                                .foregroundStyle(Color(hex: "D1D5DB"))
                                .scrollContentBackground(.hidden)
                                .background(Color.clear)
                                .padding(12)
                                .frame(minHeight: 180)
                                .focused($isFocused)
                        }
                        .background(Color(hex: "111118"))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(
                                    isFocused ? Color(hex: "6366F1").opacity(0.5) : Color(hex: "1F2937"),
                                    lineWidth: 1.5
                                )
                        )

                        HStack {
                            if !canSubmit && charCount > 0 {
                                Text("\(minLength - charCount) more characters needed")
                                    .font(.system(size: 11))
                                    .foregroundStyle(Color(hex: "F87171"))
                            } else if canSubmit {
                                Text("✓ Ready to submit")
                                    .font(.system(size: 11))
                                    .foregroundStyle(Color(hex: "10B981"))
                            }
                            Spacer()
                            Text("\(charCount)")
                                .font(.system(size: 11))
                                .foregroundStyle(canSubmit ? Color(hex: "10B981") : Color(hex: "4B5563"))
                        }
                    }

                    Spacer(minLength: 120)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
            }

            VStack(spacing: 0) {
                LinearGradient(
                    colors: [Color(hex: "0A0A0F").opacity(0), Color(hex: "0A0A0F")],
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
                        Text("Submit Reflection")
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
                                colors: [Color(hex: "10B981"), Color(hex: "059669")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                            : LinearGradient(
                                colors: [Color(hex: "1F2937"), Color(hex: "1F2937")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                    )
                    .foregroundStyle(canSubmit ? .white : Color(hex: "374151"))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
                .background(Color(hex: "0A0A0F"))
                .disabled(!canSubmit || learnVM.isSubmitting)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .alert("Error", isPresented: isShowingErrorAlert) {
            Button("Try again") {
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
            Button("OK") { learnVM.clearError() }
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
