//
//  LessonDetailView.swift
//  FinaLit
//
//  Created by aplle on 2/20/26.
//

import SwiftUI

struct LessonDetailView: View {
    let lessonID: String
    let dayID: String
    let weekID: String

    @Environment(LearnViewModel.self)          private var learnVM
    @Environment(AppPreferencesStore.self) private var preferences
    @Environment(Coordinator<LearnPages>.self) private var coordinator

    private var dayProgress: DayProgress? {
        learnVM.dayProgress(for: dayID, in: weekID)
    }

    private var currentDay: Day? {
        learnVM.days(for: weekID).first { $0.id == dayID }
    }

    private var hasReadLesson: Bool {
        dayProgress?.lessonRead == true
    }

    private var hasCompletedQuiz: Bool {
        dayProgress?.quizCompleted == true
    }

    private var primaryButtonTitle: String {
        if hasCompletedQuiz {
            return "Retake Quiz →"
        }

        if hasReadLesson {
            return "Continue to Quiz →"
        }

        return "I've read this ✓"
    }

    private var localizedLesson: Lesson? {
        learnVM.currentLesson?.resolved(for: preferences.effectiveLearningLanguage)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            AppTheme.background.ignoresSafeArea()

            if learnVM.isLoadingLesson {
                LearnLoadingView()
            } else if let lesson = localizedLesson {
                ScrollView(showsIndicators: false) {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        lessonHeader(lesson)

                        let nodes = renderNodes(for: lesson)
                        if nodes.isEmpty {
                            LessonParagraphBlock(text: "This lesson is empty.")
                        } else {
                            ForEach(nodes) { node in
                                LessonRenderNodeView(node: node)
                            }
                        }

                        Spacer(minLength: 120)
                    }
                }

                VStack(spacing: 0) {
                    LinearGradient(
                        colors: [AppTheme.background.opacity(0), AppTheme.background],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 40)

                    if hasCompletedQuiz {
                        Button {
                            coordinator.push(.quizReview(dayID, weekID))
                        } label: {
                            Text("View Last Results")
                                .font(.system(size: 15, weight: .medium))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(AppTheme.surfacePrimary)
                                .foregroundStyle(AppTheme.textPrimary)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(AppTheme.separator, lineWidth: 1)
                                )
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 12)
                        .buttonStyle(.plain)
                    }

                    Button {
                        Task { await handlePrimaryAction() }
                    } label: {
                        HStack {
                            Text(primaryButtonTitle)
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
                            LinearGradient(
                                colors: [AppTheme.accent, AppTheme.accent],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                    .background(AppTheme.background)
                    .disabled(learnVM.isSubmitting || currentDay == nil)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                LearningLanguageMenu()
            }
        }
        .task { await learnVM.loadLesson(lessonID: lessonID) }
    }

    private func renderNodes(for lesson: Lesson) -> [LessonRenderNode] {
        let explicitNodes = lesson.normalizedBlocks.map {
            LessonRenderNode(
                kind: $0.kind,
                title: $0.title,
                text: $0.text,
                items: $0.normalizedItems
            )
        }
        let articleNodes = parseBody(lesson.cleanedBody, preferStructured: false)
        let structuredBodyNodes = parseBody(lesson.cleanedBody, preferStructured: true)

        let rawNodes: [LessonRenderNode]
        switch lesson.effectiveContentMode {
        case .article:
            rawNodes = articleNodes.isEmpty ? explicitNodes : articleNodes
        case .sectioned:
            rawNodes = explicitNodes.isEmpty ? structuredBodyNodes : explicitNodes
        case .hybrid:
            rawNodes = articleNodes + explicitNodes
        case .auto:
            rawNodes = explicitNodes.isEmpty ? structuredBodyNodes : articleNodes + explicitNodes
        }

        return numberedNodes(rawNodes)
    }

    private func parseBody(_ body: String, preferStructured: Bool) -> [LessonRenderNode] {
        let normalized = body.lessonNormalizedBody
        guard !normalized.isEmpty else { return [] }

        let chunks = normalized
            .replacingOccurrences(of: "\n{3,}", with: "\n\n", options: .regularExpression)
            .components(separatedBy: "\n\n")
            .map(\.lessonTrimmedText)
            .filter { !$0.isEmpty }

        return chunks.flatMap { parseChunk($0, preferStructured: preferStructured) }
    }

    private func parseChunk(_ chunk: String, preferStructured: Bool) -> [LessonRenderNode] {
        let lines = chunk
            .components(separatedBy: .newlines)
            .map(\.lessonTrimmedText)
            .filter { !$0.isEmpty }

        guard !lines.isEmpty else { return [] }

        if preferStructured, let sectionNode = parseStructuredSection(lines) {
            return [sectionNode]
        }

        if let headingTitle = parseMarkdownHeading(lines.first ?? "") {
            let rest = Array(lines.dropFirst()).joined(separator: "\n").lessonTrimmedText
            var nodes = [LessonRenderNode(kind: .heading, title: headingTitle)]
            if !rest.isEmpty {
                nodes.append(LessonRenderNode(kind: .paragraph, text: rest))
            }
            return nodes
        }

        if let items = parseBulletItems(lines) {
            return [LessonRenderNode(kind: .bulletList, items: items)]
        }

        if let items = parseNumberedItems(lines) {
            return [LessonRenderNode(kind: .numberedList, items: items)]
        }

        return [LessonRenderNode(kind: .paragraph, text: chunk)]
    }

    private func parseStructuredSection(_ lines: [String]) -> LessonRenderNode? {
        guard let first = lines.first else { return nil }
        let range = first.range(
            of: #"^\d+\.\s+(.+)$"#,
            options: .regularExpression
        )

        guard let range else { return nil }

        let title = String(first[range]).replacingOccurrences(
            of: #"^\d+\.\s+"#,
            with: "",
            options: .regularExpression
        )
        let content = Array(lines.dropFirst()).joined(separator: "\n").lessonTrimmedText
        return LessonRenderNode(kind: .section, title: title, text: content)
    }

    private func parseMarkdownHeading(_ line: String) -> String? {
        let range = line.range(of: #"^#{1,3}\s+(.+)$"#, options: .regularExpression)
        guard let range else { return nil }

        return String(line[range])
            .replacingOccurrences(of: #"^#{1,3}\s+"#, with: "", options: .regularExpression)
            .lessonTrimmedText
    }

    private func parseBulletItems(_ lines: [String]) -> [String]? {
        let items = lines.compactMap { line -> String? in
            let trimmed = line.lessonTrimmedText
            guard trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") || trimmed.hasPrefix("• ") else {
                return nil
            }
            return String(trimmed.dropFirst(2)).lessonTrimmedText
        }

        return items.count == lines.count ? items : nil
    }

    private func parseNumberedItems(_ lines: [String]) -> [String]? {
        let items = lines.compactMap { line -> String? in
            let range = line.range(of: #"^\d+\.\s+(.+)$"#, options: .regularExpression)
            guard let range else { return nil }

            return String(line[range])
                .replacingOccurrences(of: #"^\d+\.\s+"#, with: "", options: .regularExpression)
                .lessonTrimmedText
        }

        return items.count == lines.count ? items : nil
    }

    private func numberedNodes(_ nodes: [LessonRenderNode]) -> [LessonRenderNode] {
        var sectionIndex = 0

        return nodes.map { node in
            guard node.usesSectionChrome else { return node }

            sectionIndex += 1
            var updated = node
            updated.sectionNumber = sectionIndex
            return updated
        }
    }

    private func lessonHeader(_ lesson: Lesson) -> some View {
        let difficulty = DifficultyLevel(rawValue: lesson.difficultyLevel) ?? .beginner

        return VStack(alignment: .leading, spacing: 12) {
            Text(lesson.difficultyLevel.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(difficultyColor(difficulty))
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(difficultyColor(difficulty).opacity(0.15))
                .clipShape(Capsule())

            Text(lesson.title)
                .font(.system(size: 30, weight: .medium))
                .foregroundStyle(AppTheme.textPrimary)
                .lineSpacing(4)

            HStack(spacing: 12) {
                Label(lesson.category, systemImage: "tag")
                    .font(.system(size: 12))
                    .foregroundStyle(AppTheme.textSecondary)
                Text("·")
                    .foregroundStyle(AppTheme.textTertiary)
                Label("Day \(lesson.dayNumber)", systemImage: "calendar")
                    .font(.system(size: 12))
                    .foregroundStyle(AppTheme.textSecondary)
            }

            Divider()
                .background(AppTheme.separator)
                .padding(.top, 4)
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }

    private func difficultyColor(_ level: DifficultyLevel) -> Color {
        switch level {
        case .beginner:     return AppTheme.success
        case .intermediate: return AppTheme.warning
        case .advanced:     return AppTheme.danger
        }
    }

    private func handlePrimaryAction() async {
        guard let day = currentDay, !day.quizID.isEmpty else { return }

        if !hasReadLesson {
            let didMarkRead = await learnVM.markLessonRead(weekID: weekID, dayID: dayID)
            guard didMarkRead else { return }
        }

        coordinator.push(.quiz(day.quizID, dayID, weekID))
    }
}

private struct LessonRenderNode: Identifiable {
    let id = UUID()
    let kind: LessonContentBlockKind
    var title: String = ""
    var text: String = ""
    var items: [String] = []
    var sectionNumber: Int?

    var usesSectionChrome: Bool {
        switch kind {
        case .section, .action, .caseStudy, .callout:
            return true
        default:
            return false
        }
    }
}

private struct LessonRenderNodeView: View {
    let node: LessonRenderNode

    var body: some View {
        switch node.kind {
        case .section:
            LessonSection(
                number: formattedSectionNumber,
                title: node.title.isEmpty ? "Section" : node.title,
                content: node.text,
                accent: standardSectionAccent
            )
        case .action:
            LessonSection(
                number: formattedSectionNumber,
                title: node.title.isEmpty ? "Today's Action" : node.title,
                content: node.text,
                accent: .success,
                style: .action
            )
        case .caseStudy:
            LessonSection(
                number: formattedSectionNumber,
                title: node.title.isEmpty ? "Case Study" : node.title,
                content: node.text,
                accent: .warning,
                style: .caseStudy
            )
        case .callout:
            LessonSection(
                number: formattedSectionNumber,
                title: node.title.isEmpty ? "Callout" : node.title,
                content: node.text,
                accent: .info,
                style: .callout
            )
        case .quote:
            LessonQuoteBlock(text: node.text.isEmpty ? node.title : node.text)
        case .heading:
            LessonHeadingBlock(text: node.title.isEmpty ? node.text : node.title)
        case .bulletList:
            LessonListBlock(items: node.items, ordered: false)
        case .numberedList:
            LessonListBlock(items: node.items, ordered: true)
        case .paragraph:
            LessonParagraphBlock(text: node.text)
        }
    }

    private var formattedSectionNumber: String {
        guard let sectionNumber = node.sectionNumber else { return "00" }
        return String(format: "%02d", sectionNumber)
    }

    private var standardSectionAccent: AppTone {
        let palette: [AppTone] = [.accent, .blue, .info, .warning, .success]
        let index = max((node.sectionNumber ?? 1) - 1, 0) % palette.count
        return palette[index]
    }
}

private struct LessonHeadingBlock: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 22, weight: .medium))
            .foregroundStyle(AppTheme.textPrimary)
            .lineSpacing(4)
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 4)
    }
}

private struct LessonParagraphBlock: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 16))
            .foregroundStyle(AppTheme.textPrimary)
            .lineSpacing(7)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
    }
}

private struct LessonListBlock: View {
    let items: [String]
    let ordered: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                HStack(alignment: .top, spacing: 10) {
                    Text(ordered ? "\(index + 1)." : "•")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(AppTheme.accent)
                    Text(item)
                        .font(.system(size: 16))
                        .foregroundStyle(AppTheme.textPrimary)
                        .lineSpacing(6)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }
}

private struct LessonQuoteBlock: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 16))
            .foregroundStyle(AppTheme.textPrimary)
            .lineSpacing(6)
            .italic()
            .padding(16)
            .background(AppTheme.surfacePrimary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(AppTheme.separator, lineWidth: 1)
            )
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
    }
}

private enum LessonSectionStyle {
    case standard
    case caseStudy
    case action
    case callout
}

private struct LessonSection: View {
    let number: String
    let title: String
    let content: String
    let accent: AppTone
    var style: LessonSectionStyle = .standard

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Text(number)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(AppTheme.tint(for: accent))
                Rectangle()
                    .fill(AppTheme.tint(for: accent).opacity(0.4))
                    .frame(height: 1)
                    .frame(maxWidth: .infinity)
                Text(title.uppercased())
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(AppTheme.textSecondary)
            }

            sectionContent
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 20)

        Divider()
            .background(AppTheme.surfacePrimary)
            .padding(.horizontal, 20)
    }

    @ViewBuilder
    private var sectionContent: some View {
        switch style {
        case .action:
            HStack(alignment: .top, spacing: 12) {
                Text("→")
                    .font(.system(size: 16))
                    .foregroundStyle(AppTheme.tint(for: accent))
                Text(content)
                    .font(.system(size: 15))
                    .foregroundStyle(AppTheme.textPrimary)
                    .lineSpacing(5)
            }
            .padding(16)
            .background(AppTheme.success.opacity(0.07))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(AppTheme.success.opacity(0.2), lineWidth: 1)
            )
        case .caseStudy:
            Text(content)
                .font(.system(size: 15))
                .foregroundStyle(AppTheme.textPrimary)
                .lineSpacing(5)
                .italic()
                .padding(16)
                .background(AppTheme.warning.opacity(0.07))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppTheme.warning.opacity(0.2), lineWidth: 1)
                )
        case .callout:
            Text(content)
                .font(.system(size: 15))
                .foregroundStyle(AppTheme.textPrimary)
                .lineSpacing(5)
                .padding(16)
                .background(AppTheme.info.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppTheme.info.opacity(0.2), lineWidth: 1)
                )
        case .standard:
            Text(content)
                .font(.system(size: 16))
                .foregroundStyle(AppTheme.textPrimary)
                .lineSpacing(6)
        }
    }
}

private extension String {
    var lessonTrimmedText: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var lessonNormalizedBody: String {
        replacingOccurrences(of: "\u{00A0}", with: " ")
            .replacingOccurrences(of: "\u{2028}", with: "\n")
            .replacingOccurrences(of: "\u{2029}", with: "\n")
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
            .lessonTrimmedText
    }
}
