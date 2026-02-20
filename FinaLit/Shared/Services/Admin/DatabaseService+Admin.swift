// DatabaseService+Admin.swift
// Shared/Services/
//
// Admin-only write methods for creating content.
// These are called only from AdminViewModel.
// Regular users never call these.

import Foundation
import FirebaseFirestore

extension DatabaseService {

    // MARK: - Admin: Fetch all weeks (published + drafts)
    func fetchAllWeeks() async throws -> [Week] {
        let snapshot = try await weeksCollection
            .order(by: "weekNumber", descending: false)
            .getDocuments()
        return try snapshot.documents.compactMap {
            try $0.data(as: Week.self)
        }
    }

    // MARK: - Admin: Create Week
    func createWeek(_ week: Week) throws {
        guard let id = week.id, !id.isEmpty else { throw DBError.invalidDocumentID }
        try weeksCollection.document(id).setData(from: week)
    }

    // MARK: - Admin: Create Day
    func createDay(_ day: Day, weekID: String) throws {
        guard let id = day.id, !id.isEmpty else { throw DBError.invalidDocumentID }
        try daysCollection(weekID).document(id).setData(from: day)
    }

    // MARK: - Admin: Create Lesson
    func createLesson(_ lesson: Lesson) throws {
        guard let id = lesson.id, !id.isEmpty else { throw DBError.invalidDocumentID }
        try lessonsCollection.document(id).setData(from: lesson)
    }

    // MARK: - Admin: Create Quiz
    func createQuiz(_ quiz: Quiz) throws {
        guard let id = quiz.id, !id.isEmpty else { throw DBError.invalidDocumentID }
        try quizzesCollection.document(id).setData(from: quiz)
    }

    // MARK: - Admin: Create Daily Tip
    func createDailyTip(_ tip: DailyTip) throws {
        guard let id = tip.id, !id.isEmpty else { throw DBError.invalidDocumentID }
        try dailyTipsCollection.document(id).setData(from: tip)
    }

    // MARK: - Admin: Publish / Unpublish Week
    func setWeekPublished(_ weekID: String, published: Bool) throws {
        try weeksCollection
            .document(weekID)
            .setData(from: ["isPublished": published], merge: true)
    }
}
