//
//  lives.swift
//  FinaLit
//
//  Created by aplle on 2/20/26.
//


// FirestorePath+Transactions.swift
// Core/ (or wherever your FirestorePath enum lives)
//
// Add these cases to your existing FirestorePath enum.
// Shown as an extension here for clarity.

import Foundation

extension FirestorePath {

    // ── Transaction subcollections ─────────────────────────────────────────
    static func transactions(_ uid: String) -> String {
        "users/\(uid)/transactions"
    }

    static func recurring(_ uid: String) -> String {
        "users/\(uid)/recurringTemplates"
    }

    static func budgetLimits(_ uid: String) -> String {
        "users/\(uid)/budgetLimits"
    }

    static func goals(_ uid: String) -> String {
        "users/\(uid)/goals"
    }

    static func monthlySnapshots(_ uid: String) -> String {
        "users/\(uid)/monthlySnapshots"
    }

    static func financialSummary(_ uid: String) -> String {
        "users/\(uid)/financialSummary"
    }
}