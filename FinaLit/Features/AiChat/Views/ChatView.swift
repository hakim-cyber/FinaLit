//
//  ChatView.swift
//  FinaLit
//
//  Created by Codex on 2/20/26.
//

import SwiftUI
import SwiftData

struct ChatView: View {
    @Environment(ChatViewModel.self) private var viewModel
    @Environment(MainViewModel.self) private var mainVM
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        @Bindable var viewModel = viewModel

        ZStack {
            ChatPalette.background.ignoresSafeArea()

            VStack(spacing: 0) {
                header

                ScrollViewReader { proxy in
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 14) {
                            disclaimerCard

                            if viewModel.messages.isEmpty && !viewModel.isLoading {
                                emptyState
                            }

                            ForEach(viewModel.messages, id: \.id) { message in
                                messageCard(message)
                                    .id(message.id)
                            }

                            if viewModel.isSending {
                                assistantTypingCard(text: viewModel.liveAssistantText)
                                    .id("typing-indicator")
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                    }
                    .onChange(of: viewModel.messages.count) { _, _ in
                        scrollToBottom(with: proxy)
                    }
                    .onChange(of: viewModel.isSending) { _, _ in
                        scrollToBottom(with: proxy)
                    }
                    .onChange(of: viewModel.liveAssistantText) { _, _ in
                        scrollToBottom(with: proxy)
                    }
                }

                if let error = viewModel.errorMessage, !error.isEmpty {
                    Text(error)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(ChatPalette.error)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 6)
                }

                composer
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 14)
                    .background(ChatPalette.background)
            }

            if viewModel.isLoading {
                ProgressView()
                    .tint(.white)
                    .scaleEffect(1.2)
                    .padding(20)
                    .background(ChatPalette.surface, in: RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(ChatPalette.border, lineWidth: 1)
                    )
            }
        }
        .navigationBarHidden(true)
        .task {
            if mainVM.aiContext == nil && !mainVM.isLoadingHome {
                await mainVM.loadHome()
            }
            viewModel.updateFinancialContext(mainVM.aiContext)
            viewModel.bootstrapIfNeeded(context: modelContext)
        }
        .onChange(of: mainVM.aiContext?.formattedPrompt) { _, _ in
            viewModel.updateFinancialContext(mainVM.aiContext)
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("FinaLit")
                    .font(.system(size: 34, weight: .light, design: .serif))
                    .foregroundStyle(.white)

                Text("AI Financial Advisor")
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundStyle(ChatPalette.muted)
            }

            Spacer()

            Button {
                viewModel.clearChat(context: modelContext)
            } label: {
                Text("CLEAR")
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundStyle(ChatPalette.accent)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(ChatPalette.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(ChatPalette.border, lineWidth: 1)
                    )
            }
            .disabled(viewModel.messages.isEmpty || viewModel.isSending)
        }
        .padding(.horizontal, 20)
        .padding(.top, 14)
        .padding(.bottom, 8)
    }

    private var disclaimerCard: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("NOTICE")
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundStyle(ChatPalette.warning)

            Text("Educational guidance only. Not professional financial advice.")
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(ChatPalette.warningText)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .background(ChatPalette.warningBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(ChatPalette.warningBorder, lineWidth: 1)
        )
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Start a financial question")
                .font(.system(size: 18, weight: .medium, design: .serif))
                .foregroundStyle(.white)

            Text("Try: \"Can I afford a 900€ laptop?\"")
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(ChatPalette.muted)

            Text("Or: \"How should I begin investing safely?\"")
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(ChatPalette.muted)
        }
        .padding(16)
        .background(ChatPalette.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(ChatPalette.border, lineWidth: 1)
        )
    }

    private var composer: some View {
        @Bindable var viewModel = viewModel

        return HStack(alignment: .bottom, spacing: 10) {
            TextField(
                "Ask your question...",
                text: $viewModel.draft,
                axis: .vertical
            )
            .lineLimit(1...4)
            .font(.system(size: 14, design: .monospaced))
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(ChatPalette.surface)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(ChatPalette.border, lineWidth: 1)
            )
            .disabled(viewModel.isSending)
            .submitLabel(.send)
            .onSubmit {
                Task {
                    viewModel.updateFinancialContext(mainVM.aiContext)
                    await viewModel.sendMessage(context: modelContext)
                }
            }

            Button {
                Task {
                    viewModel.updateFinancialContext(mainVM.aiContext)
                    await viewModel.sendMessage(context: modelContext)
                }
            } label: {
                Image(systemName: "arrow.up")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(
                        LinearGradient(
                            colors: [ChatPalette.accent, ChatPalette.accentDark],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(Circle())
            }
            .disabled(viewModel.draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isSending)
        }
    }

    private func messageCard(_ message: ChatMessageEntity) -> some View {
        let isUser = message.role == .user

        return HStack {
            if isUser { Spacer(minLength: 36) }

            VStack(alignment: .leading, spacing: 8) {
                Text(isUser ? "YOU" : "ADVISOR")
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundStyle(isUser ? Color.white.opacity(0.85) : ChatPalette.accent)

                Text(message.text)
                    .font(.system(size: 15, design: .serif))
                    .foregroundStyle(isUser ? .white : ChatPalette.messageText)
                    .lineSpacing(4)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(14)
            .background(messageBackground(isUser: isUser))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(messageBorder(isUser: isUser), lineWidth: 1)
            )
            .frame(maxWidth: 320, alignment: .leading)

            if !isUser { Spacer(minLength: 36) }
        }
    }

    private func assistantTypingCard(text: String?) -> some View {
        let displayText = text?.trimmingCharacters(in: .whitespacesAndNewlines)
        let hasText = !(displayText ?? "").isEmpty

      return  HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text("ADVISOR")
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundStyle(ChatPalette.accent)

                Text(hasText ? (displayText ?? "") : "Thinking...")
                    .font(.system(size: hasText ? 15 : 14, design: hasText ? .serif : .monospaced))
                    .foregroundStyle(hasText ? ChatPalette.messageText : ChatPalette.muted)
                    .lineSpacing(4)
            }
            .padding(14)
            .background(ChatPalette.surface)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(ChatPalette.border, lineWidth: 1)
            )
            .frame(maxWidth: 320, alignment: .leading)

            Spacer(minLength: 36)
        }
    }

    private func messageBackground(isUser: Bool) -> some ShapeStyle {
        if isUser {
            return AnyShapeStyle(
                LinearGradient(
                    colors: [ChatPalette.accent, ChatPalette.accentDark],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        }

        return AnyShapeStyle(ChatPalette.surface)
    }

    private func messageBorder(isUser: Bool) -> Color {
        isUser ? ChatPalette.accent.opacity(0.2) : ChatPalette.border
    }

    private func scrollToBottom(with proxy: ScrollViewProxy) {
        if viewModel.isSending {
            withAnimation(.easeOut(duration: 0.2)) {
                proxy.scrollTo("typing-indicator", anchor: .bottom)
            }
            return
        }

        guard let id = viewModel.messages.last?.id else { return }
        withAnimation(.easeOut(duration: 0.2)) {
            proxy.scrollTo(id, anchor: .bottom)
        }
    }
}

private enum ChatPalette {
    static let background = Color(hex: "0A0A0F")
    static let surface = Color(hex: "111118")
    static let border = Color(hex: "1F2937")
    static let muted = Color(hex: "6B7280")

    static let accent = Color(hex: "6366F1")
    static let accentDark = Color(hex: "4F46E5")

    static let warning = Color(hex: "F59E0B")
    static let warningText = Color(hex: "FCD34D")
    static let warningBackground = Color(hex: "3B1F0A").opacity(0.45)
    static let warningBorder = Color(hex: "78350F")

    static let error = Color(hex: "F87171")
    static let messageText = Color(hex: "D1D5DB")
}
