//
//  GoalProgressPatch.swift
//  FinaLit
//
//  Created by aplle on 2/20/26.
//


// DatabaseService+Transactions.swift
// Shared/Services/
//
// All transaction, budget, goal, snapshot, and recurring methods.
// Consistent with existing DatabaseService patterns:
//   - Writes: throws (not async)
//   - Reads:  async throws
//   - Models: @DocumentID var id: String?
//   - Writes: setData(from:) with patch structs for partials
//   - Reads:  data(as:)

import Foundation
import FirebaseFirestore

extension DatabaseService {

    // MARK: - Firestore Path Helpers (private)

    private func transactionsCollection(_ uid: String) -> CollectionReference {
        db.collection(FirestorePath.transactions(uid))
    }

    private func transactionDocument(_ uid: String, _ txID: String) -> DocumentReference {
        transactionsCollection(uid).document(txID)
    }

    private func recurringCollection(_ uid: String) -> CollectionReference {
        db.collection(FirestorePath.recurring(uid))
    }

    private func budgetLimitsDocument(_ uid: String) -> DocumentReference {
        db.collection(FirestorePath.budgetLimits(uid)).document("limits")
    }

    private func goalsCollection(_ uid: String) -> CollectionReference {
        db.collection(FirestorePath.goals(uid))
    }

    private func goalDocument(_ uid: String, _ goalID: String) -> DocumentReference {
        goalsCollection(uid).document(goalID)
    }

    private func snapshotsCollection(_ uid: String) -> CollectionReference {
        db.collection(FirestorePath.monthlySnapshots(uid))
    }

    private func snapshotDocument(_ uid: String, _ month: String) -> DocumentReference {
        snapshotsCollection(uid).document(month)
    }

    private func financialSummaryDocument(_ uid: String) -> DocumentReference {
        db.collection(FirestorePath.financialSummary(uid)).document("summary")
    }

    private func debtAccountsCollection(_ uid: String) -> CollectionReference {
        db.collection(FirestorePath.debtAccounts(uid))
    }

    private func debtAccountDocument(_ uid: String, _ debtID: String) -> DocumentReference {
        debtAccountsCollection(uid).document(debtID)
    }

    private func monthClosuresCollection(_ uid: String) -> CollectionReference {
        db.collection(FirestorePath.monthClosures(uid))
    }

    private func monthClosureDocument(_ uid: String, _ month: String) -> DocumentReference {
        monthClosuresCollection(uid).document(month)
    }

    // MARK: - Patch Structs

    private struct GoalProgressPatch: Codable {
        var currentAmount: Double
        var isCompleted:   Bool
    }

    private struct GoalCompletedPatch: Codable {
        var isCompleted: Bool
    }

    private struct RecurringActivePatch: Codable {
        var isActive: Bool
    }

    private struct DebtBalancePatch: Codable {
        var currentBalance: Double
        var updatedAt: Date
        var isClosed: Bool
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - Transactions
    // ─────────────────────────────────────────────────────────────────────────

    /// Add a new transaction (income or expense)
    func addTransaction(_ transaction: Transaction, uid: String) throws {
        let collection = transactionsCollection(uid)
        let doc = if let id = transaction.id, !id.isEmpty {
            collection.document(id)
        } else {
            collection.document()
        }
        var payload = transaction
        payload.id = nil
        try doc.setData(from: payload)
    }

    /// Fetch all transactions, most recent first
    func fetchTransactions(uid: String) async throws -> [Transaction] {
        let snapshot = try await transactionsCollection(uid)
            .order(by: "date", descending: true)
            .getDocuments()
        return try snapshot.documents.compactMap {
            try $0.data(as: Transaction.self)
        }
    }

    /// Fetch transactions for a specific month ("yyyy-MM")
    func fetchTransactions(uid: String, month: String) async throws -> [Transaction] {
        let calendar  = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"

        guard let date      = formatter.date(from: month),
              let startDate = calendar.date(from: calendar.dateComponents([.year, .month], from: date)),
              let endDate   = calendar.date(byAdding: .month, value: 1, to: startDate)
        else { throw DBError.unknown("Invalid month format: \(month)") }

        let snapshot = try await transactionsCollection(uid)
            .whereField("date", isGreaterThanOrEqualTo: Timestamp(date: startDate))
            .whereField("date", isLessThan: Timestamp(date: endDate))
            .order(by: "date", descending: true)
            .getDocuments()

        return try snapshot.documents.compactMap {
            try $0.data(as: Transaction.self)
        }
    }

    /// Fetch transactions for a specific category
    func fetchTransactions(uid: String, category: TransactionCategory) async throws -> [Transaction] {
        let snapshot = try await transactionsCollection(uid)
            .whereField("category", isEqualTo: category.rawValue)
            .order(by: "date", descending: true)
            .getDocuments()
        return try snapshot.documents.compactMap {
            try $0.data(as: Transaction.self)
        }
    }

    /// Delete a transaction
    func deleteTransaction(uid: String, transactionID: String) async throws {
        try await transactionDocument(uid, transactionID).delete()
    }

    /// Stream real-time transaction updates (most recent first)
    func streamTransactions(uid: String) -> AsyncStream<[Transaction]> {
        let query = transactionsCollection(uid)
            .order(by: "date", descending: true)

        return AsyncStream { continuation in
            let listener = query.addSnapshotListener { snapshot, error in
                guard error == nil else {
                    continuation.finish()
                    return
                }
                let docs         = snapshot?.documents ?? []
                let transactions = docs.compactMap { try? $0.data(as: Transaction.self) }
                continuation.yield(transactions)
            }
            continuation.onTermination = { _ in listener.remove() }
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - Recurring Templates
    // ─────────────────────────────────────────────────────────────────────────

    func createRecurringTemplate(_ template: RecurringTemplate, uid: String) throws {
        guard let id = template.id, !id.isEmpty else { throw DBError.invalidDocumentID }
        var payload = template
        payload.id = nil
        try recurringCollection(uid).document(id).setData(from: payload)
    }

    func fetchRecurringTemplates(uid: String) async throws -> [RecurringTemplate] {
        let snapshot = try await recurringCollection(uid)
            .whereField("isActive", isEqualTo: true)
            .getDocuments()
        return try snapshot.documents.compactMap {
            try $0.data(as: RecurringTemplate.self)
        }
    }

    func deactivateRecurringTemplate(uid: String, templateID: String) throws {
        try recurringCollection(uid)
            .document(templateID)
            .setData(from: RecurringActivePatch(isActive: false), merge: true)
    }

    func deleteRecurringTemplate(uid: String, templateID: String) async throws {
        try await recurringCollection(uid).document(templateID).delete()
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - Budget Limits
    // ─────────────────────────────────────────────────────────────────────────

    /// Fetch all budget limits for the user (single document, array of limits)
    func fetchBudgetLimits(uid: String) async throws -> [BudgetLimit] {
        let snapshot = try await budgetLimitsDocument(uid).getDocument()
        guard snapshot.exists else { return [] }

        // Stored as array of maps under "limits" key
        guard let data  = snapshot.data(),
              let array = data["limits"] as? [[String: Any]]
        else { return [] }

        return array.compactMap { dict -> BudgetLimit? in
            guard let category = dict["category"] as? String,
                  let cat      = TransactionCategory(rawValue: category),
                  let limit    = dict["limit"] as? Double
            else { return nil }
            return BudgetLimit(
                id:       dict["id"] as? String,
                category: cat,
                limit:    limit
            )
        }
    }

    /// Save all budget limits at once (overwrites previous)
    func saveBudgetLimits(_ limits: [BudgetLimit], uid: String) async throws {
        let encoded: [[String: Any]] = limits.map { limit in
            [
                "id":       limit.id ?? UUID().uuidString,
                "category": limit.category.rawValue,
                "limit":    limit.limit
            ]
        }
        try await budgetLimitsDocument(uid).setData(["limits": encoded])
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - Financial Goals
    // ─────────────────────────────────────────────────────────────────────────

    func createGoal(_ goal: FinancialGoal, uid: String) throws {
        guard let id = goal.id, !id.isEmpty else { throw DBError.invalidDocumentID }
        var payload = goal
        payload.id = nil
        try goalsCollection(uid).document(id).setData(from: payload)
    }

    func fetchGoals(uid: String) async throws -> [FinancialGoal] {
        let snapshot = try await goalsCollection(uid)
            .order(by: "createdAt", descending: false)
            .getDocuments()
        return try snapshot.documents.compactMap {
            try $0.data(as: FinancialGoal.self)
        }
    }

    func updateGoalProgress(uid: String, goalID: String, currentAmount: Double, isCompleted: Bool) throws {
        try goalDocument(uid, goalID)
            .setData(from: GoalProgressPatch(
                currentAmount: currentAmount,
                isCompleted:   isCompleted
            ), merge: true)
    }

    func markGoalCompleted(uid: String, goalID: String) throws {
        try goalDocument(uid, goalID)
            .setData(from: GoalCompletedPatch(isCompleted: true), merge: true)
    }

    func deleteGoal(uid: String, goalID: String) async throws {
        try await goalDocument(uid, goalID).delete()
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - Debt Accounts
    // ─────────────────────────────────────────────────────────────────────────

    func createDebtAccount(_ debt: DebtAccount, uid: String) throws {
        guard let id = debt.id, !id.isEmpty else { throw DBError.invalidDocumentID }
        var payload = debt
        payload.id = nil
        try debtAccountDocument(uid, id).setData(from: payload)
    }

    func fetchDebtAccounts(uid: String) async throws -> [DebtAccount] {
        let snapshot = try await debtAccountsCollection(uid)
            .order(by: "createdAt", descending: false)
            .getDocuments()
        return try snapshot.documents.compactMap {
            try $0.data(as: DebtAccount.self)
        }
    }

    func updateDebtBalance(uid: String, debtID: String, newBalance: Double) throws {
        let clamped = max(newBalance, 0)
        try debtAccountDocument(uid, debtID).setData(from: DebtBalancePatch(
            currentBalance: clamped,
            updatedAt: Date(),
            isClosed: clamped <= 0
        ), merge: true)
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - Month Closures
    // ─────────────────────────────────────────────────────────────────────────

    func markMonthClosed(uid: String, record: MonthCloseRecord) throws {
        guard !record.month.isEmpty else { throw DBError.invalidDocumentID }
        var payload = record
        payload.id = nil
        try monthClosureDocument(uid, record.month).setData(from: payload)
    }

    func isMonthClosed(uid: String, month: String) async throws -> Bool {
        let doc = try await monthClosureDocument(uid, month).getDocument()
        return doc.exists
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - Monthly Snapshots
    // ─────────────────────────────────────────────────────────────────────────

    func saveMonthlySnapshot(_ snapshot: MonthlySnapshot, uid: String) throws {
        guard !snapshot.month.isEmpty else { throw DBError.invalidDocumentID }
        var payload = snapshot
        payload.id = nil
        try snapshotDocument(uid, snapshot.month).setData(from: payload)
    }

    func fetchMonthlySnapshot(uid: String, month: String) async throws -> MonthlySnapshot? {
        let doc = try await snapshotDocument(uid, month).getDocument()
        guard doc.exists else { return nil }
        return try doc.data(as: MonthlySnapshot.self)
    }

    /// Fetch last N monthly snapshots for trend charts
    func fetchRecentSnapshots(uid: String, limit: Int = 6) async throws -> [MonthlySnapshot] {
        let snapshot = try await snapshotsCollection(uid)
            .order(by: "month", descending: true)
            .limit(to: limit)
            .getDocuments()
        return try snapshot.documents.compactMap {
            try $0.data(as: MonthlySnapshot.self)
        }
        .reversed()  // return oldest first for chart display
    }
}

// MARK: - FirestorePath extensions (add these to your FirestorePath enum)
//
// static func transactions(_ uid: String)      → "users/\(uid)/transactions"
// static func recurring(_ uid: String)         → "users/\(uid)/recurringTemplates"
// static func budgetLimits(_ uid: String)      → "users/\(uid)/budgetLimits"
// static func goals(_ uid: String)             → "users/\(uid)/goals"
// static func monthlySnapshots(_ uid: String)  → "users/\(uid)/monthlySnapshots"
// static func financialSummary(_ uid: String)  → "users/\(uid)/financialSummary"
// static func debtAccounts(_ uid: String)      → "users/\(uid)/debtAccounts"
// static func monthClosures(_ uid: String)     → "users/\(uid)/monthClosures"
