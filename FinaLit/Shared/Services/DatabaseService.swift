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
import Observation
import FirebaseFirestore

@Observable
final class DatabaseService {
    let db = Firestore.firestore()

    private var usersCollection: CollectionReference {
        db.collection(FirestorePath.users)
    }

    private func userDocument(_ uid: String) -> DocumentReference {
        usersCollection.document(uid)
    }

    private struct UserProfilePatch: Codable {
        let profile: UserProfile
    }

    private struct FinancialProfilePatch: Codable {
        let financialProfile: FinancialProfile
    }

    private struct BehaviorProfilePatch: Codable {
        let behaviorProfile: BehaviorProfile
    }

    // MARK: - User

    /// Called once after register — creates the user document in Firestore
    func createUser(_ user: User) throws {
        guard let uid = user.id, !uid.isEmpty else {
            throw DBError.invalidDocumentID
        }

        try userDocument(uid).setData(from: user)
    }

    /// Called on login + app launch restore — fetches full User document
    func fetchUser(uid: String) async throws -> User {
        let snapshot = try await userDocument(uid).getDocument()

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

    func saveUserProfile(_ profile: UserProfile, uid: String) throws {
        try userDocument(uid).setData(from: UserProfilePatch(profile: profile), merge: true)
    }

    func saveFinancialProfile(_ profile: FinancialProfile, uid: String) throws {
        try userDocument(uid).setData(from: FinancialProfilePatch(financialProfile: profile), merge: true)
    }

    func saveBehaviorProfile(_ profile: BehaviorProfile, uid: String) throws {
        try userDocument(uid).setData(from: BehaviorProfilePatch(behaviorProfile: profile), merge: true)
    }

    // MARK: - Expenses

    func addExpense(_ expense: Expense, uid: String) throws {
        let expensesCollection = db.collection(FirestorePath.expenses(uid))
        let targetDocument = if let expenseID = expense.id, !expenseID.isEmpty {
            expensesCollection.document(expenseID)
        } else {
            expensesCollection.document()
        }

        try targetDocument.setData(from: expense)
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

    /// Streams real-time expense updates sorted by most recent.
    func streamExpenses(uid: String) -> AsyncStream<[Expense]> {
        let query = db
            .collection(FirestorePath.expenses(uid))
            .order(by: "date", descending: true)

        return AsyncStream { continuation in
            let listener = query.addSnapshotListener { snapshot, error in
                if let error {
                    #if DEBUG
                    print("Expense stream failed: \(error.localizedDescription)")
                    #endif
                    continuation.finish()
                    return
                }

                let documents = snapshot?.documents ?? []
                let expenses = documents.compactMap { try? $0.data(as: Expense.self) }
                continuation.yield(expenses)
            }

            continuation.onTermination = { _ in
                listener.remove()
            }
        }
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
    case invalidDocumentID
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .userNotFound:    return "User data not found."
        case .notFound:        return "Requested data not found."
        case .encodingFailed:  return "Failed to process data."
        case .invalidDocumentID: return "Missing document ID."
        case .unknown(let m):  return m
        }
    }
}
