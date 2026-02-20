//
//  LearnViewModel.swift
//  FinaLit
//
//  Created by aplle on 2/20/26.
//


// LearnViewModel.swift
// Features/Learn/ViewModels/
//
// Orchestrates all learning section logic.
// Owns all state for the entire Learn tab.
// All views read from this — no view fetches Firestore directly.

import Foundation

@Observable
final class LearnViewModel {

    // MARK: - Admin Content State
    var todaysTip: DailyTip?
    var publishedWeeks: [Week] = []

    // MARK: - Days Cache
    // weekID → [Day] — loaded per week on demand
    var daysCache: [String: [Day]] = [:]

    // MARK: - Lesson / Quiz State
    // Loaded on demand when user opens a day
    var currentLesson: Lesson?
    var currentQuiz: Quiz?

    // MARK: - User Progress State
    var weekProgressList: [WeekProgress] = []

    // dayProgressCache: weekID → [DayProgress]
    var dayProgressCache: [String: [DayProgress]] = [:]

    var reflections: [Reflection] = []
    var learningSummary: LearningSummary = LearningSummary()

    // MARK: - Quiz Session State
    // Tracks current quiz answers in memory — not saved until quiz complete
    var currentQuizAnswers:  [String: Int] = [:]   // questionID → selectedIndex
    var currentQuizRevealed: [String: Bool] = [:]  // questionID → answered
    var currentQuestionIndex: Int = 0

    // MARK: - UI State
    var isLoadingHome:    Bool = false
    var isLoadingLesson:  Bool = false
    var isLoadingQuiz:    Bool = false
    var isSubmitting:     Bool = false
    var errorMessage:     String?

    // MARK: - Dependencies
    private let db:      DatabaseService
    private let session: UserSession

    init(db: DatabaseService, session: UserSession) {
        self.db      = db
        self.session = session
    }

    func onTabAppear() async {
        guard let uid else { return }
        do {
            learningSummary = try await db.fetchLearningSummary(uid: uid)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    // MARK: - Computed: current user ID
    private var uid: String? { session.user?.id }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - Home Load
    // Called once when LearnHomeView appears
    // ─────────────────────────────────────────────────────────────────────────

    func loadHome() async {
        guard let uid else { return }
        isLoadingHome = true
        errorMessage  = nil
        defer { isLoadingHome = false }

        do {
            // 1. Fetch in parallel — tip + weeks + progress
            async let tipTask      = db.fetchTodaysTip()
            async let weeksTask    = db.fetchPublishedWeeks()
            async let progressTask = db.fetchAllWeekProgress(uid: uid)

            let (tip, weeks, progress) = try await (tipTask, weeksTask, progressTask)

            todaysTip        = tip
            publishedWeeks   = weeks
            weekProgressList = progress

            // 2. Initialize week progress docs if this is first time
            try await db.initializeWeekProgressIfNeeded(uid: uid, weeks: weeks)

            // 3. Re-fetch progress after initialization
            weekProgressList = try await db.fetchAllWeekProgress(uid: uid)

            // 4. Fetch learning summary
            learningSummary = try await db.fetchLearningSummary(uid: uid)

            // 5. Preload unlocked week/day caches so "Continue" works on first open
            await preloadUnlockedWeekData(uid: uid, weeks: weeks, progressList: weekProgressList)

        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - Week Load
    // Called when user opens WeekDetailView
    // ─────────────────────────────────────────────────────────────────────────

    func loadWeek(weekID: String) async {
        guard let uid else { return }
        errorMessage = nil

        do {
            // Load days for this week if not cached
            if daysCache[weekID] == nil {
                let days = try await db.fetchDays(weekID: weekID)
                daysCache[weekID] = days

                // Initialize day progress if needed
                let weekNumber = publishedWeeks.first { $0.id == weekID }?.weekNumber ?? 0
                try await db.initializeDayProgressIfNeeded(
                    uid: uid,
                    weekID: weekID,
                    weekNumber: weekNumber,
                    days: days
                )
            }

            // Load day progress for this week if not cached
            if dayProgressCache[weekID] == nil {
                dayProgressCache[weekID] = try await db.fetchAllDayProgress(uid: uid, weekID: weekID)
            }

        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - Lesson Load
    // Called when user opens LessonDetailView
    // ─────────────────────────────────────────────────────────────────────────

    func loadLesson(lessonID: String) async {
        isLoadingLesson = true
        currentLesson   = nil
        errorMessage    = nil
        defer { isLoadingLesson = false }

        do {
            currentLesson = try await db.fetchLesson(lessonID: lessonID)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // Called when user taps "I've read this" at bottom of lesson
    func markLessonRead(weekID: String, dayID: String) async {
        guard let uid else { return }
        errorMessage = nil

        do {
            try await db.markLessonRead(uid: uid, weekID: weekID, dayID: dayID)

            // Update local cache immediately — no need to re-fetch
            updateDayProgressLocally(weekID: weekID, dayID: dayID) { progress in
                progress.lessonRead   = true
                progress.lessonReadAt = Date()
            }

            try await db.recalculateAndSaveLearningSummary(uid: uid)
            learningSummary = try await db.fetchLearningSummary(uid: uid)

        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - Quiz Load + Session
    // ─────────────────────────────────────────────────────────────────────────

    func loadQuiz(quizID: String) async {
        isLoadingQuiz = true
        currentQuiz   = nil
        errorMessage  = nil
        resetQuizSession()
        defer { isLoadingQuiz = false }

        do {
            currentQuiz = try await db.fetchQuiz(quizID: quizID)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // Called when user taps an answer option
    func answerQuestion(questionID: String, selectedIndex: Int) {
        guard currentQuizAnswers[questionID] == nil else { return } // already answered
        currentQuizAnswers[questionID]  = selectedIndex
        currentQuizRevealed[questionID] = true
    }

    func advanceToNextQuestion() {
        guard let quiz = currentQuiz else { return }
        if currentQuestionIndex < quiz.questions.count - 1 {
            currentQuestionIndex += 1
        }
    }

    var isQuizComplete: Bool {
        guard let quiz = currentQuiz else { return false }
        return currentQuizAnswers.count == quiz.questions.count
    }

    var currentQuizScore: Int {
        guard let quiz = currentQuiz else { return 0 }
        return quiz.questions.filter { question in
            currentQuizAnswers[question.id ?? ""] == question.correctIndex
        }.count
    }

    var wrongQuestionIDs: [String] {
        guard let quiz = currentQuiz else { return [] }
        return quiz.questions.compactMap { question in
            guard let id = question.id else { return nil }
            let answered = currentQuizAnswers[id]
            return answered != question.correctIndex ? id : nil
        }
    }

    // Called after user finishes last question and taps "See Results"
    @discardableResult
    func submitQuiz(weekID: String, dayID: String) async -> Bool {
        guard let uid,
              let quiz = currentQuiz else { return false }

        isSubmitting = true
        errorMessage = nil
        defer { isSubmitting = false }

        let score  = currentQuizScore
        let total  = quiz.questions.count
        let wrong  = wrongQuestionIDs

        do {
            try await db.saveQuizResult(
                uid:     uid,
                weekID:  weekID,
                dayID:   dayID,
                score:   score,
                total:   total,
                wrongIDs: wrong
            )

            // Update local cache
            updateDayProgressLocally(weekID: weekID, dayID: dayID) { progress in
                progress.quizCompleted    = true
                progress.quizScore        = score
                progress.totalQuestions   = total
                progress.wrongQuestionIDs = wrong
                progress.completedAt      = Date()
            }

            // Unlock next day if this wasn't the last day
            try await unlockNextDayIfNeeded(weekID: weekID, completedDayID: dayID)

            // Recalculate summary
            try await db.recalculateAndSaveLearningSummary(uid: uid)
            learningSummary = try await db.fetchLearningSummary(uid: uid)
            return true

        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    private func resetQuizSession() {
        currentQuizAnswers   = [:]
        currentQuizRevealed  = [:]
        currentQuestionIndex = 0
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - Reflection
    // ─────────────────────────────────────────────────────────────────────────

    func submitReflection(weekID: String, weekTitle: String, content: String) async -> Bool {
        guard let uid else { return false }

        isSubmitting = true
        errorMessage = nil
        defer { isSubmitting = false }

        let reflection = Reflection(
            id:          UUID().uuidString,
            weekNumber:  weekProgress(for: weekID)?.weekNumber ?? 0,
            weekTitle:   weekTitle,
            content:     content,
            submittedAt: Date()
        )

        do {
            // 1. Save reflection + mark week complete (done inside saveReflection)
            try  db.saveReflection(reflection, uid: uid, weekID: weekID)

            // 2. Update local week progress cache
            updateWeekProgressLocally(weekID: weekID) { progress in
                progress.isCompleted  = true
                progress.completedAt  = Date()
                progress.reflectionID = reflection.id
            }

            // 3. Add to local reflections list
            reflections.insert(reflection, at: 0)

            // 4. Unlock next week
            try await unlockNextWeekIfNeeded(completedWeekID: weekID)

            // 5. Recalculate summary
            try await db.recalculateAndSaveLearningSummary(uid: uid)
            learningSummary = try await db.fetchLearningSummary(uid: uid)

            return true

        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func loadReflections() async {
        guard let uid else { return }
        do {
            reflections = try await db.fetchReflections(uid: uid)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - Unlock Logic
    // ─────────────────────────────────────────────────────────────────────────

    private func unlockNextDayIfNeeded(weekID: String, completedDayID: String) async throws {
        guard let uid else { return }

        let days        = daysCache[weekID] ?? []
        let dayProgresses = dayProgressCache[weekID] ?? []

        // Find the day number we just completed
        guard let completedDay = days.first(where: { $0.id == completedDayID }) else { return }

        let nextDayNumber = completedDay.dayNumber + 1

        // Find next day
        guard let nextDay = days.first(where: { $0.dayNumber == nextDayNumber }),
              let nextDayID = nextDay.id else { return }

        // Check not already unlocked
        let nextDayProgress = dayProgresses.first { $0.id == nextDayID }
        guard nextDayProgress?.isUnlocked != true else { return }

        // Unlock it
        try  db.unlockDay(uid: uid, weekID: weekID, dayID: nextDayID)

        // Update local cache
        updateDayProgressLocally(weekID: weekID, dayID: nextDayID) { progress in
            progress.isUnlocked = true
        }
    }

    private func unlockNextWeekIfNeeded(completedWeekID: String) async throws {
        guard let uid else { return }

        let completedWeek = publishedWeeks.first { $0.id == completedWeekID }
        guard let completedWeekNumber = completedWeek?.weekNumber else { return }

        let nextWeekNumber = completedWeekNumber + 1
        guard let nextWeek = publishedWeeks.first(where: { $0.weekNumber == nextWeekNumber }),
              let nextWeekID = nextWeek.id else { return }

        // Check not already unlocked
        let nextWeekProgress = weekProgressList.first { $0.weekID == nextWeekID }
        guard nextWeekProgress?.isUnlocked != true else { return }

        // Unlock in Firestore
        try  db.unlockWeek(uid: uid, weekID: nextWeekID)

        // Update local cache
        updateWeekProgressLocally(weekID: nextWeekID) { progress in
            progress.isUnlocked = true
        }
    }

    private func preloadUnlockedWeekData(
        uid: String,
        weeks: [Week],
        progressList: [WeekProgress]
    ) async {
        let unlockedWeekIDs = Set(progressList.filter(\.isUnlocked).map(\.weekID))
        guard !unlockedWeekIDs.isEmpty else { return }

        for week in weeks {
            guard let weekID = week.id, unlockedWeekIDs.contains(weekID) else { continue }

            do {
                let days: [Day]
                if let cachedDays = daysCache[weekID], !cachedDays.isEmpty {
                    days = cachedDays
                } else {
                    days = try await db.fetchDays(weekID: weekID)
                    daysCache[weekID] = days
                }

                try await db.initializeDayProgressIfNeeded(
                    uid: uid,
                    weekID: weekID,
                    weekNumber: week.weekNumber,
                    days: days
                )

                dayProgressCache[weekID] = try await db.fetchAllDayProgress(uid: uid, weekID: weekID)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - Convenience Accessors
    // Used by views to get state without knowing the data structure
    // ─────────────────────────────────────────────────────────────────────────

    func weekProgress(for weekID: String) -> WeekProgress? {
        weekProgressList.first { $0.weekID == weekID }
    }

    func dayProgress(for dayID: String, in weekID: String) -> DayProgress? {
        dayProgressCache[weekID]?.first { $0.id == dayID }
    }

    func days(for weekID: String) -> [Day] {
        daysCache[weekID] ?? []
    }

    // Overall progress percentage — used for learning level display
    var overallProgressPercentage: Double {
        let totalDays = publishedWeeks.count * 7
        guard totalDays > 0 else { return 0 }
        let completedDays = dayProgressCache.values
            .flatMap { $0 }
            .filter { $0.isFullyComplete }
            .count
        return (Double(completedDays) / Double(totalDays)) * 100
    }

    // Next action for the continue banner on home screen
    var nextUnlockedDay: (weekID: String, dayID: String, dayNumber: Int)? {
        for week in publishedWeeks {
            guard let weekID = week.id else { continue }
            let wProgress = weekProgress(for: weekID)
            guard wProgress?.isUnlocked == true else { continue }

            let days      = daysCache[weekID] ?? []
            let dProgress = dayProgressCache[weekID] ?? []

            for day in days.sorted(by: { $0.dayNumber < $1.dayNumber }) {
                guard let dayID = day.id else { continue }
                let dp = dProgress.first { $0.id == dayID }
                if dp?.isUnlocked == true && dp?.isFullyComplete == false {
                    return (weekID: weekID, dayID: dayID, dayNumber: day.dayNumber)
                }
            }
        }
        return nil
    }

    // Whether all 6 non-reflection days are done — unlocks reflection day
    func isReflectionUnlocked(weekID: String) -> Bool {
        let days      = daysCache[weekID] ?? []
        let dProgress = dayProgressCache[weekID] ?? []

        // All non-reflection days (1-6) must be fully complete
        let nonReflectionDays = days.filter { !$0.isReflection }
        return nonReflectionDays.allSatisfy { day in
            dProgress.first { $0.id == day.id }?.isFullyComplete == true
        }
    }

    // Whether a specific day is the reflection day
    func isReflectionDay(_ day: Day) -> Bool {
        day.isReflection
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - Local Cache Mutations
    // Update in-memory state immediately after writes
    // so UI reacts without waiting for a Firestore re-fetch
    // ─────────────────────────────────────────────────────────────────────────

    private func updateDayProgressLocally(
        weekID: String,
        dayID: String,
        mutation: (inout DayProgress) -> Void
    ) {
        guard var progresses = dayProgressCache[weekID],
              let index = progresses.firstIndex(where: { $0.id == dayID }) else { return }
        mutation(&progresses[index])
        dayProgressCache[weekID] = progresses
    }

    private func updateWeekProgressLocally(
        weekID: String,
        mutation: (inout WeekProgress) -> Void
    ) {
        guard let index = weekProgressList.firstIndex(where: { $0.weekID == weekID }) else { return }
        mutation(&weekProgressList[index])
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - Error Handling
    // ─────────────────────────────────────────────────────────────────────────

    func clearError() {
        errorMessage = nil
    }
}
