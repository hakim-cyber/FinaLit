//
//  DatabaseService+Learning.swift
//  FinaLit
//

import Foundation
import FirebaseFirestore

extension DatabaseService {
    // MARK: - Helpers

    private func mapDBError(_ error: Error) -> DBError {
        if let dbError = error as? DBError {
            return dbError
        }
        return DBError.unknown(error.localizedDescription)
    }

     var dailyTipsCollection: CollectionReference {
        db.collection(FirestorePath.dailyTips())
    }

     var weeksCollection: CollectionReference {
        db.collection(FirestorePath.weeks())
    }

     var lessonsCollection: CollectionReference {
        db.collection(FirestorePath.lessons)
    }

     var quizzesCollection: CollectionReference {
        db.collection(FirestorePath.quizzes)
    }

     func daysCollection(_ weekID: String) -> CollectionReference {
        db.collection(FirestorePath.days(weekID: weekID))
    }

     func weekProgressCollection(_ uid: String) -> CollectionReference {
        db.collection(FirestorePath.weekProgress(uid: uid))
    }

    private func weekProgressDocument(_ uid: String, _ weekID: String) -> DocumentReference {
        weekProgressCollection(uid).document(weekID)
    }

    private func dayProgressCollection(_ uid: String, _ weekID: String) -> CollectionReference {
        db.collection(FirestorePath.dayProgress(uid: uid, weekID: weekID))
    }

    private func dayProgressDocument(_ uid: String, _ weekID: String, _ dayID: String) -> DocumentReference {
        dayProgressCollection(uid, weekID).document(dayID)
    }

    private func reflectionsCollection(_ uid: String) -> CollectionReference {
        db.collection(FirestorePath.reflections(uid: uid))
    }

    private func learningSummaryDocument(_ uid: String) -> DocumentReference {
        db.document(FirestorePath.learningSummaryDoc(uid: uid))
    }

    private func emptyLearningSummary() -> LearningSummary {
        LearningSummary(
            totalLessonsRead: 0,
            totalQuizzesDone: 0,
            totalWeeksCompleted: 0,
            averageQuizScore: 0.0,
            currentStreak: 0,
            longestStreak: 0,
            lastActiveDate: nil
        )
    }

    // MARK: - Patch Models

    private struct LessonReadPatch: Codable {
        let lessonRead: Bool
        let lessonReadAt: Date
    }

    private struct QuizResultPatch: Codable {
        let quizCompleted: Bool
        let quizScore: Int
        let totalQuestions: Int
        let wrongQuestionIDs: [String]
        let completedAt: Date
    }

    private struct WeekCompletionPatch: Codable {
        let completedAt: Date
        let isCompleted: Bool
        let reflectionID: String
    }

    private struct WeekUnlockPatch: Codable {
        let isUnlocked: Bool
    }

    // MARK: - Writes

    /// Creates a week progress document when a user enters a week for the first time.
    func createWeekProgress(_ progress: WeekProgress, uid: String) throws {
        do {
            guard let progressID = progress.id, !progressID.isEmpty else {
                throw DBError.invalidDocumentID
            }

            try weekProgressDocument(uid, progressID).setData(from: progress)
        } catch {
            throw mapDBError(error)
        }
    }

    /// Creates a day progress document when a user opens a day for the first time.
    func createDayProgress(_ progress: DayProgress, uid: String, weekID: String) throws {
        do {
            guard !weekID.isEmpty else {
                throw DBError.invalidDocumentID
            }
            guard let progressID = progress.id, !progressID.isEmpty else {
                throw DBError.invalidDocumentID
            }

            try dayProgressDocument(uid, weekID, progressID).setData(from: progress)
        } catch {
            throw mapDBError(error)
        }
    }

    /// Updates selected week-progress fields after completion/reflection events.
    func updateWeekProgress(uid: String, weekID: String, data: [String: Any]) async throws {
        do {
            guard !weekID.isEmpty else {
                throw DBError.invalidDocumentID
            }

            try await weekProgressDocument(uid, weekID).updateData(data)
        } catch {
            throw mapDBError(error)
        }
    }

    /// Updates selected day-progress fields for partial state changes.
    func updateDayProgress(uid: String, weekID: String, dayID: String, data: [String: Any]) async throws {
        do {
            guard !weekID.isEmpty, !dayID.isEmpty else {
                throw DBError.invalidDocumentID
            }

            try await dayProgressDocument(uid, weekID, dayID).updateData(data)
        } catch {
            throw mapDBError(error)
        }
    }

    /// Marks a lesson as read when the user finishes reading that day’s lesson.
    func markLessonRead(uid: String, weekID: String, dayID: String) throws {
        do {
            guard !weekID.isEmpty, !dayID.isEmpty else {
                throw DBError.invalidDocumentID
            }

            let patch = LessonReadPatch(lessonRead: true, lessonReadAt: Date())
            try dayProgressDocument(uid, weekID, dayID).setData(from: patch, merge: true)
        } catch {
            throw mapDBError(error)
        }
    }

    /// Marks a lesson as read, then recalculates learning stats for dashboard badges.
    func markLessonRead(uid: String, weekID: String, dayID: String) async throws {
        do {
            guard !weekID.isEmpty, !dayID.isEmpty else {
                throw DBError.invalidDocumentID
            }

            try await dayProgressDocument(uid, weekID, dayID).updateData([
                "lessonRead": true,
                "lessonReadAt": Timestamp(date: Date())
            ])
            try await recalculateAndSaveLearningSummary(uid: uid)
        } catch {
            throw mapDBError(error)
        }
    }

    /// Saves quiz completion results after quiz submit on a learning day.
    func saveQuizResult(
        uid: String,
        weekID: String,
        dayID: String,
        score: Int,
        total: Int,
        wrongIDs: [String]
    ) throws {
        do {
            guard !weekID.isEmpty, !dayID.isEmpty else {
                throw DBError.invalidDocumentID
            }

            let patch = QuizResultPatch(
                quizCompleted: true,
                quizScore: score,
                totalQuestions: total,
                wrongQuestionIDs: wrongIDs,
                completedAt: Date()
            )
            try dayProgressDocument(uid, weekID, dayID).setData(from: patch, merge: true)
        } catch {
            throw mapDBError(error)
        }
    }

    /// Saves quiz completion results, then refreshes aggregate learning stats.
    func saveQuizResult(
        uid: String,
        weekID: String,
        dayID: String,
        score: Int,
        total: Int,
        wrongIDs: [String]
    ) async throws {
        do {
            guard !weekID.isEmpty, !dayID.isEmpty else {
                throw DBError.invalidDocumentID
            }

            try await dayProgressDocument(uid, weekID, dayID).updateData([
                "quizCompleted": true,
                "quizScore": score,
                "totalQuestions": total,
                "wrongQuestionIDs": wrongIDs,
                "completedAt": Timestamp(date: Date())
            ])
            try await recalculateAndSaveLearningSummary(uid: uid)
        } catch {
            throw mapDBError(error)
        }
    }

    /// Saves weekly reflection text and marks the supplied week progress as completed.
    func saveReflection(_ reflection: Reflection, uid: String, weekID: String) throws {
        do {
            guard !weekID.isEmpty else {
                throw DBError.invalidDocumentID
            }
            guard let reflectionID = reflection.id, !reflectionID.isEmpty else {
                throw DBError.invalidDocumentID
            }

            try reflectionsCollection(uid).document(reflectionID).setData(from: reflection)
            try weekProgressDocument(uid, weekID).setData(
                from: WeekCompletionPatch(completedAt: Date(), isCompleted: true, reflectionID: reflectionID),
                merge: true
            )
        } catch {
            throw mapDBError(error)
        }
    }

    /// Saves a reflection from the weekly reflection screen and unlocks the next week if present.
    func saveReflection(_ reflection: Reflection, uid: String) async throws {
        do {
            var reflectionToSave = reflection
            if reflectionToSave.id?.isEmpty ?? true {
                reflectionToSave.id = UUID().uuidString
            }
            guard let reflectionID = reflectionToSave.id, !reflectionID.isEmpty else {
                throw DBError.invalidDocumentID
            }

            try reflectionsCollection(uid).document(reflectionID).setData(from: reflectionToSave)

            let allWeekProgress = try await fetchAllWeekProgress(uid: uid)
            guard let currentWeek = allWeekProgress.first(where: { $0.weekNumber == reflectionToSave.weekNumber }) else {
                throw DBError.notFound
            }

            try await updateWeekProgress(
                uid: uid,
                weekID: currentWeek.weekID,
                data: [
                    "isCompleted": true,
                    "completedAt": Timestamp(date: Date()),
                    "reflectionID": reflectionID
                ]
            )

            if let nextWeek = allWeekProgress.first(where: { $0.weekNumber == currentWeek.weekNumber + 1 }) {
                try await updateWeekProgress(uid: uid, weekID: nextWeek.weekID, data: ["isUnlocked": true])
            }

            try await recalculateAndSaveLearningSummary(uid: uid)
        } catch {
            throw mapDBError(error)
        }
    }

    /// Unlocks a week progress document when the prior week is completed.
    func unlockWeek(uid: String, weekID: String) throws {
        do {
            guard !weekID.isEmpty else {
                throw DBError.invalidDocumentID
            }

            try weekProgressDocument(uid, weekID).setData(from: WeekUnlockPatch(isUnlocked: true), merge: true)
        } catch {
            throw mapDBError(error)
        }
    }

    /// Unlocks a day progress document when the previous day is completed.
    func unlockDay(uid: String, weekID: String, dayID: String) throws {
        do {
            guard !weekID.isEmpty, !dayID.isEmpty else {
                throw DBError.invalidDocumentID
            }

            try dayProgressDocument(uid, weekID, dayID).setData(from: WeekUnlockPatch(isUnlocked: true), merge: true)
        } catch {
            throw mapDBError(error)
        }
    }

    /// Persists a full learning summary snapshot to the fixed summary document.
    func saveLearningSummary(_ summary: LearningSummary, uid: String) throws {
        do {
            try learningSummaryDocument(uid).setData(from: summary)
        } catch {
            throw mapDBError(error)
        }
    }

    // MARK: - Reads

    // MARK: - Daily Tip

    /// Fetches today's admin-uploaded tip. Returns nil if no tip is scheduled today.
    func fetchTodaysTip() async throws -> DailyTip? {
        do {
            let calendar = Calendar.current
            let startOfToday = calendar.startOfDay(for: Date())
            guard let startOfTomorrow = calendar.date(byAdding: .day, value: 1, to: startOfToday) else {
                throw DBError.unknown("Failed to compute day boundary.")
            }

            let snapshot = try await dailyTipsCollection
                .whereField("date", isGreaterThanOrEqualTo: Timestamp(date: startOfToday))
                .whereField("date", isLessThan: Timestamp(date: startOfTomorrow))
                .order(by: "date", descending: false)
                .limit(to: 1)
                .getDocuments()

            guard let document = snapshot.documents.first else {
                return nil
            }
            return try document.data(as: DailyTip.self)
        } catch {
            throw mapDBError(error)
        }
    }

    // MARK: - Weeks (admin content, read-only for users)

    /// Fetches all published learning weeks ordered by week number.
    func fetchPublishedWeeks() async throws -> [Week] {
        do {
            let snapshot = try await weeksCollection
                .whereField("isPublished", isEqualTo: true)
                .order(by: "weekNumber", descending: false)
                .getDocuments()

            return try snapshot.documents.compactMap { try $0.data(as: Week.self) }
        } catch {
            throw mapDBError(error)
        }
    }

    /// Fetches all day documents for a week ordered by day number.
    func fetchDays(weekID: String) async throws -> [Day] {
        do {
            guard !weekID.isEmpty else {
                throw DBError.invalidDocumentID
            }

            let snapshot = try await daysCollection(weekID)
                .order(by: "dayNumber", descending: false)
                .getDocuments()

            return try snapshot.documents.compactMap { try $0.data(as: Day.self) }
        } catch {
            throw mapDBError(error)
        }
    }

    /// Fetches one lesson document for a day when a lesson view opens.
    func fetchLesson(lessonID: String) async throws -> Lesson {
        do {
            guard !lessonID.isEmpty else {
                throw DBError.invalidDocumentID
            }

            let snapshot = try await lessonsCollection.document(lessonID).getDocument()
            guard snapshot.exists else {
                throw DBError.notFound
            }

            return try snapshot.data(as: Lesson.self)
        } catch {
            throw mapDBError(error)
        }
    }

    /// Fetches one quiz document for a day when a quiz starts.
    func fetchQuiz(quizID: String) async throws -> Quiz {
        do {
            guard !quizID.isEmpty else {
                throw DBError.invalidDocumentID
            }

            let snapshot = try await quizzesCollection.document(quizID).getDocument()
            guard snapshot.exists else {
                throw DBError.notFound
            }

            return try snapshot.data(as: Quiz.self)
        } catch {
            throw mapDBError(error)
        }
    }

    // MARK: - Week Progress

    /// Fetches all week-progress records to render the learning week list.
    func fetchAllWeekProgress(uid: String) async throws -> [WeekProgress] {
        do {
            let snapshot = try await weekProgressCollection(uid)
                .order(by: "weekNumber", descending: false)
                .getDocuments()

            return try snapshot.documents.compactMap { try $0.data(as: WeekProgress.self) }
        } catch {
            throw mapDBError(error)
        }
    }

    // MARK: - Day Progress

    /// Fetches all day-progress records for a week to drive day-level UI state.
    func fetchAllDayProgress(uid: String, weekID: String) async throws -> [DayProgress] {
        do {
            guard !weekID.isEmpty else {
                throw DBError.invalidDocumentID
            }

            let snapshot = try await dayProgressCollection(uid, weekID)
                .order(by: "dayNumber", descending: false)
                .getDocuments()

            return try snapshot.documents.compactMap { try $0.data(as: DayProgress.self) }
        } catch {
            throw mapDBError(error)
        }
    }

    // MARK: - Reflection

    /// Fetches all submitted reflections for profile/history screens, newest first.
    func fetchReflections(uid: String) async throws -> [Reflection] {
        do {
            let snapshot = try await reflectionsCollection(uid)
                .order(by: "submittedAt", descending: true)
                .getDocuments()

            return try snapshot.documents.compactMap { try $0.data(as: Reflection.self) }
        } catch {
            throw mapDBError(error)
        }
    }

    // MARK: - Learning Summary

    /// Fetches the learning summary document used by progress/insights surfaces.
    func fetchLearningSummary(uid: String) async throws -> LearningSummary {
        do {
            let snapshot = try await learningSummaryDocument(uid).getDocument()
            guard snapshot.exists else {
                return emptyLearningSummary()
            }

            return try snapshot.data(as: LearningSummary.self)
        } catch {
            throw mapDBError(error)
        }
    }

    // MARK: - Initialization

    /// Initializes missing week-progress docs after published weeks are fetched.
    func initializeWeekProgressIfNeeded(uid: String, weeks: [Week]) async throws {
        do {
            let existingProgress = try await fetchAllWeekProgress(uid: uid)
            let existingWeekIDs = Set(existingProgress.map(\.weekID))
            let existingWeekNumbers = Set(existingProgress.map(\.weekNumber))

            for week in weeks {
                let weekID = week.id ?? ""
                let alreadyExistsByID = !weekID.isEmpty && existingWeekIDs.contains(weekID)
                let alreadyExistsByNumber = existingWeekNumbers.contains(week.weekNumber)
                guard !alreadyExistsByID, !alreadyExistsByNumber else {
                    continue
                }

                let progress = WeekProgress(
                    id: week.id ?? UUID().uuidString,
                    weekID: weekID,
                    weekNumber: week.weekNumber,
                    startedAt: nil,
                    completedAt: nil,
                    isUnlocked: week.weekNumber == 1,
                    isCompleted: false,
                    reflectionID: nil
                )
                try createWeekProgress(progress, uid: uid)
            }
        } catch {
            throw mapDBError(error)
        }
    }

    /// Initializes missing day-progress docs after week day content is loaded.
    func initializeDayProgressIfNeeded(uid: String, weekID: String, weekNumber: Int, days: [Day]) async throws {
        do {
            _ = weekNumber
            guard !weekID.isEmpty else {
                throw DBError.invalidDocumentID
            }

            let existingProgress = try await fetchAllDayProgress(uid: uid, weekID: weekID)
            let existingDayNumbers = Set(existingProgress.map(\.dayNumber))

            for day in days where !existingDayNumbers.contains(day.dayNumber) {
                let progress = DayProgress(
                    id: day.id ?? UUID().uuidString,
                    dayNumber: day.dayNumber,
                    lessonRead: false,
                    lessonReadAt: nil,
                    quizCompleted: false,
                    quizScore: nil,
                    totalQuestions: nil,
                    wrongQuestionIDs: [],
                    isUnlocked: day.dayNumber == 1,
                    completedAt: nil
                )
                try createDayProgress(progress, uid: uid, weekID: weekID)
            }
        } catch {
            throw mapDBError(error)
        }
    }

    // MARK: - Recalculate

    /// Recomputes learning metrics from progress source data and persists summary.
    func recalculateAndSaveLearningSummary(uid: String) async throws {
        do {
            let existingSummary = try await fetchLearningSummary(uid: uid)
            let allWeekProgress = try await fetchAllWeekProgress(uid: uid)

            var allDayProgress: [DayProgress] = []
            for weekProgress in allWeekProgress {
                let days = try await fetchAllDayProgress(uid: uid, weekID: weekProgress.weekID)
                allDayProgress.append(contentsOf: days)
            }

            let totalLessonsRead = allDayProgress.filter(\.lessonRead).count
            let totalQuizzesDone = allDayProgress.filter(\.quizCompleted).count
            let totalWeeksCompleted = allWeekProgress.filter(\.isCompleted).count

            let quizPercentages: [Double] = allDayProgress.compactMap { day in
                guard day.quizCompleted, let score = day.quizScore else {
                    return nil
                }
                guard let total = day.totalQuestions, total > 0 else {
                    return Double(score)
                }
                return (Double(score) / Double(total)) * 100
            }
            let averageQuizScore = quizPercentages.isEmpty
                ? 0.0
                : quizPercentages.reduce(0.0, +) / Double(quizPercentages.count)

            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            let currentStreak: Int

            if let last = existingSummary.lastActiveDate {
                let lastDay = calendar.startOfDay(for: last)
                let diff = calendar.dateComponents([.day], from: lastDay, to: today).day ?? 0
                if diff == 0 {
                    currentStreak = existingSummary.currentStreak
                } else if diff == 1 {
                    currentStreak = existingSummary.currentStreak + 1
                } else {
                    currentStreak = 1
                }
            } else {
                currentStreak = 1
            }

            let longestStreak = max(existingSummary.longestStreak, currentStreak)

            let summary = LearningSummary(
                totalLessonsRead: totalLessonsRead,
                totalQuizzesDone: totalQuizzesDone,
                totalWeeksCompleted: totalWeeksCompleted,
                averageQuizScore: averageQuizScore,
                currentStreak: currentStreak,
                longestStreak: longestStreak,
                lastActiveDate: Date()
            )
            try saveLearningSummary(summary, uid: uid)
        } catch {
            throw mapDBError(error)
        }
    }
}

