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
    @Environment(Coordinator<ChatPages>.self) private var coordinator
    @Environment(\.modelContext) private var modelContext
    @State private var showConsentPrompt = false

    var body: some View {
        @Bindable var viewModel = viewModel

        ZStack {
            ChatPalette.background.ignoresSafeArea()

            VStack(spacing: 0) {
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
                        .font(AppTheme.Typography.detail)
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
                    .tint(AppTheme.inverseText)
                    .scaleEffect(1.2)
                    .appSurface(.primary, padding: 20, cornerRadius: AppTheme.CornerRadius.medium)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Clear") {
                    viewModel.clearChat(context: modelContext)
                }
                .disabled(viewModel.messages.isEmpty || viewModel.isSending)
            }
            if #available(iOS 26.0, *) {
                ToolbarSpacer(.flexible, placement: .topBarTrailing)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    coordinator.push(.settings, type: .fullScreenCover)
                } label: {
                    Image(systemName: "gearshape")
                        .font(AppTheme.Typography.toolbarIcon)
                }
            }
        }
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
        .alert("Allow AI data sharing?", isPresented: $showConsentPrompt) {
            Button("Not now", role: .cancel) {}
            Button("Allow & Send") {
                viewModel.setAIDataSharingConsent(true)
                Task { await sendMessageNow() }
            }
        } message: {
            Text("To answer questions, FinaLit sends your message and selected financial profile data to Google Gemini through Firebase AI Logic.")
        }
    }

    private var disclaimerCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 8) {
                Text("NOTICE")
                    .font(AppTheme.Typography.badge)
                    .foregroundStyle(ChatPalette.warning)

                Text("Educational guidance only. Not professional financial advice.")
                    .font(AppTheme.Typography.detail)
                    .foregroundStyle(ChatPalette.warningText)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Divider()
                .overlay(AppTheme.softBorder(for: .warning))

            HStack(spacing: 10) {
                Text(viewModel.hasAIDataSharingConsent ? "AI data sharing: Enabled" : "AI data sharing: Off")
                    .font(AppTheme.Typography.badge)
                    .foregroundStyle(ChatPalette.warningText)

                Spacer()

                Button(viewModel.hasAIDataSharingConsent ? "Turn Off" : "Review") {
                    if viewModel.hasAIDataSharingConsent {
                        viewModel.setAIDataSharingConsent(false)
                    } else {
                        showConsentPrompt = true
                    }
                }
                .font(AppTheme.Typography.badge)
                .foregroundStyle(ChatPalette.warning)
            }
        }
        .appSurface(.tinted(.warning), padding: 12, cornerRadius: AppTheme.CornerRadius.medium)
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Start a financial question")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(AppTheme.textPrimary)

            Text("Try: \"Can I afford a 900\(AppRegion.currencySymbol) laptop?\"")
                .font(AppTheme.Typography.caption)
                .foregroundStyle(ChatPalette.muted)

            Text("Or: \"How should I begin investing safely?\"")
                .font(AppTheme.Typography.caption)
                .foregroundStyle(ChatPalette.muted)
        }
        .appSurface(.primary, padding: 16, cornerRadius: AppTheme.CornerRadius.large)
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
            .font(AppTheme.Typography.body)
            .foregroundStyle(AppTheme.textPrimary)
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
                requestSend()
            }

            Button {
                requestSend()
            } label: {
                Image(systemName: "arrow.up")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppTheme.inverseText)
                    .frame(width: 44, height: 44)
                    .background(ChatPalette.accent)
                    .clipShape(Circle())
            }
            .disabled(viewModel.isSending)
        }
    }

    private func messageCard(_ message: ChatMessageEntity) -> some View {
        let isUser = message.role == .user

        return HStack {
            if isUser { Spacer(minLength: 36) }

            VStack(alignment: .leading, spacing: 8) {
                Text(isUser ? "YOU" : "ADVISOR")
                    .font(AppTheme.Typography.badge)
                    .foregroundStyle(isUser ? AppTheme.inverseText.opacity(0.9) : ChatPalette.accent)

                Text(message.text)
                    .font(AppTheme.Typography.body)
                    .foregroundStyle(isUser ? AppTheme.inverseText : ChatPalette.messageText)
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
                    .font(AppTheme.Typography.badge)
                    .foregroundStyle(ChatPalette.accent)

                Text(hasText ? (displayText ?? "") : "Thinking...")
                    .font(.system(size: hasText ? 15 : 14))
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
            return AnyShapeStyle(ChatPalette.accent)
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

    private func requestSend() {
        let isDraftEmpty = viewModel.draft
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .isEmpty

        if isDraftEmpty {
            KeyboardUX.dismiss()
            return
        }

        guard viewModel.hasAIDataSharingConsent else {
            showConsentPrompt = true
            return
        }

        Task { await sendMessageNow() }
    }

    private func sendMessageNow() async {
        viewModel.updateFinancialContext(mainVM.aiContext)
        await viewModel.sendMessage(context: modelContext)
    }
}

private enum ChatPalette {
    static let background = AppTheme.background
    static let surface = AppTheme.surfacePrimary
    static let border = AppTheme.separator
    static let muted = AppTheme.textSecondary

    static let accent = AppTheme.accent

    static let warning = AppTheme.warning
    static let warningText = AppTheme.textPrimary

    static let error = AppTheme.danger
    static let messageText = AppTheme.textPrimary
}
