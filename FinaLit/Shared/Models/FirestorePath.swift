//
//  FirestorePath.swift
//  FinaLit
//
//  Created by aplle on 2/18/26.
//


// FirestoreStructure.swift
// Shared/Services/
// This file is REFERENCE ONLY — shows exact Firestore paths used across services

/*
Firestore structure:

users/
  {userID}/
    ── (fields): email, name, createdAt
    ── (documentID): userID (same as Firebase Auth UID)
    ── profile/          → UserProfile      (after onboarding step 1)
    ── financialProfile/ → FinancialProfile (after onboarding step 2+3)
    ── behaviorProfile/  → BehaviorProfile  (after onboarding step 4)
    ── learningProgress/ → LearningProgress (auto-created on first lesson open)
    
    transactions/        → subcollection
      {transactionID}/   → Transaction
    
    chatHistory/         → subcollection
      {messageID}/       → ChatMessage

lessons/               → top-level (same for all users, preloaded)
  {lessonID}/          → Lesson

quizzes/               → top-level
  {quizID}/            → Quiz
*/

// MARK: - Firestore Path Constants

enum FirestorePath {
    static let users = "users"
    static let chatHistory = "chatHistory"
    static let lessons = "lessons"
    static let quizzes = "quizzes"
    
    static func user(_ uid: String) -> String { "users/\(uid)" }
    static func chat(_ uid: String) -> String { "users/\(uid)/chatHistory" }

    static func weeks() -> String { "weeks" }
    static func days(weekID: String) -> String { "weeks/\(weekID)/days" }
    static func dailyTips() -> String { "dailyTips" }
    static func weekProgress(uid: String) -> String { "users/\(uid)/weekProgress" }
    static func dayProgress(uid: String, weekID: String) -> String { "users/\(uid)/weekProgress/\(weekID)/dayProgress" }
    static func reflections(uid: String) -> String { "users/\(uid)/reflections" }
    static func learningSummaryDoc(uid: String) -> String { "users/\(uid)/learningSummary/summary" }
}
