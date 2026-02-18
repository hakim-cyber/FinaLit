//
//  DatabaseService.swift
//  FinaLit
//
//  Created by aplle on 2/18/26.
//


// DatabaseService.swift
// Shared/Services/
//
// Pure Firestore wrapper.
// Handles all reads and writes. Returns Swift models — never Firestore types.
// ViewModels call this — never touch Firestore directly from ViewModels.

import Foundation
import FirebaseFirestore

@Observable
class DatabaseService {

    private var db: Firestore { Firestore.firestore() }

    // MARK: - User

    /// Called once after register — creates the user document in Firestore
    func createUser(_ user: User) async throws {
        let data = try Firestore.Encoder().encode(user)
        try await db
            .collection(FirestorePath.users)
            .document(user.id)
            .setData(data)
    }

    /// Called on login + app launch restore — fetches full User document
    func fetchUser(uid: String) async throws -> User {
        let snapshot = try await db
            .collection(FirestorePath.users)
            .document(uid)
            .getDocument()

        guard snapshot.exists else { throw DBError.userNotFound }

        return try snapshot.data(as: User.self)
    }

    /// Generic update — pass only the fields that changed
    /// Example: updateUser(uid: id, data: ["profile": encodedProfile])
    func updateUser(uid: String, data: [String: Any]) async throws {
        try await db
            .collection(FirestorePath.users)
            .document(uid)
            .updateData(data)
    }

    // MARK: - Onboarding profile saves
    // Each onboarding step saves its own profile independently.
    // This way if user quits mid-onboarding, progress is not lost.

    func saveUserProfile(_ profile: UserProfile, uid: String) async throws {
        let data = try Firestore.Encoder().encode(profile)
        try await updateUser(uid: uid, data: ["profile": data])
    }

    func saveFinancialProfile(_ profile: FinancialProfile, uid: String) async throws {
        let data = try Firestore.Encoder().encode(profile)
        try await updateUser(uid: uid, data: ["financialProfile": data])
    }

    func saveBehaviorProfile(_ profile: BehaviorProfile, uid: String) async throws {
        let data = try Firestore.Encoder().encode(profile)
        try await updateUser(uid: uid, data: ["behaviorProfile": data])
    }

    // MARK: - Expenses

    func addExpense(_ expense: Expense, uid: String) async throws {
        let data = try Firestore.Encoder().encode(expense)
        try await db
            .collection(FirestorePath.expenses(uid))
            .document(expense.id)
            .setData(data)
    }

    func fetchExpenses(uid: String) async throws -> [Expense] {
        let snapshot = try await db
            .collection(FirestorePath.expenses(uid))
            .order(by: "date", descending: true)
            .getDocuments()

        return try snapshot.documents.compactMap {
            try $0.data(as: Expense.self)
        }
    }

    func deleteExpense(expenseID: String, uid: String) async throws {
        try await db
            .collection(FirestorePath.expenses(uid))
            .document(expenseID)
            .delete()
    }

//    // MARK: - Chat History
//
//    func saveMessage(_ message: ChatMessage, uid: String) async throws {
//        let data = try Firestore.Encoder().encode(message)
//        try await db
//            .collection(FirestorePath.chat(uid))
//            .document(message.id)
//            .setData(data)
//    }
//
//    func fetchChatHistory(uid: String) async throws -> [ChatMessage] {
//        let snapshot = try await db
//            .collection(FirestorePath.chat(uid))
//            .order(by: "timestamp", descending: false)
//            .getDocuments()
//
//        return try snapshot.documents.compactMap {
//            try $0.data(as: ChatMessage.self)
//        }
//    }

//    // MARK: - Learning Progress
//
//    func saveLearningProgress(_ progress: LearningProgress, uid: String) async throws {
//        let data = try Firestore.Encoder().encode(progress)
//        try await updateUser(uid: uid, data: ["learningProgress": data])
//    }
//
//    // MARK: - Lessons (read-only, same for all users)
//
//    func fetchLessons() async throws -> [Lesson] {
//        let snapshot = try await db
//            .collection(FirestorePath.lessons)
//            .order(by: "day", descending: false)
//            .getDocuments()
//
//        return try snapshot.documents.compactMap {
//            try $0.data(as: Lesson.self)
//        }
//    }
//
//    func fetchLesson(id: String) async throws -> Lesson {
//        let snapshot = try await db
//            .collection(FirestorePath.lessons)
//            .document(id)
//            .getDocument()
//
//        guard snapshot.exists else { throw DBError.notFound }
//        return try snapshot.data(as: Lesson.self)
//    }
//
//    // MARK: - Quizzes
//
//    func fetchQuiz(id: String) async throws -> Quiz {
//        let snapshot = try await db
//            .collection(FirestorePath.quizzes)
//            .document(id)
//            .getDocument()
//
//        guard snapshot.exists else { throw DBError.notFound }
//        return try snapshot.data(as: Quiz.self)
//    }
}

// MARK: - DBError

enum DBError: LocalizedError {
    case userNotFound
    case notFound
    case encodingFailed
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .userNotFound:    return "User data not found."
        case .notFound:        return "Requested data not found."
        case .encodingFailed:  return "Failed to process data."
        case .unknown(let m):  return m
        }
    }
}
