//
//  AuthService.swift
//  FinaLit
//
//  Created by aplle on 2/18/26.
//

// AuthService.swift
// Shared/Services/
//
// Pure Firebase Auth wrapper.
// No SwiftUI. No business logic. Only auth operations.
// ViewModels call this — never call Firebase directly from ViewModels.

import Foundation
import Observation
import FirebaseAuth

@Observable
final class AuthService {

    // MARK: - Current Session

    /// The currently authenticated Firebase user.
    private(set) var currentUser: FirebaseAuth.User?
    private var authListener: AuthStateDidChangeListenerHandle?

    init() {
        currentUser = Auth.auth().currentUser
        authListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.currentUser = user
        }
    }

    /// Returns Firebase UID if a user is already logged in (persisted across launches)
    var currentUID: String? {
        currentUser?.uid
    }

    var isLoggedIn: Bool {
        currentUser != nil
    }

    // MARK: - Register

    /// Creates a new Firebase Auth account.
    /// Returns the new user's UID — caller is responsible for saving to Firestore.
    @MainActor
    func register(email: String, password: String) async throws -> String {
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            return result.user.uid
        } catch let error as NSError {
            throw AuthError.map(error)
        }
    }

    // MARK: - Login

    /// Signs in with email + password.
    /// Returns UID — caller fetches full User from Firestore.
    @MainActor
    func login(email: String, password: String) async throws -> String {
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            return result.user.uid
        } catch let error as NSError {
            throw AuthError.map(error)
        }
    }

    // MARK: - Sign Out

    func signOut() throws {
        do {
            try Auth.auth().signOut()
        } catch let error as NSError {
            throw AuthError.map(error)
        }
    }

    // MARK: - Password Reset

    @MainActor
    func sendPasswordReset(email: String) async throws {
        do {
            try await Auth.auth().sendPasswordReset(withEmail: email)
        } catch let error as NSError {
            throw AuthError.map(error)
        }
    }

    deinit {
        if let authListener {
            Auth.auth().removeStateDidChangeListener(authListener)
        }
    }
}

// MARK: - AuthError
// Maps Firebase NSError codes to readable app errors.
// Add cases as needed.

enum AuthError: LocalizedError {
    case invalidEmail
    case wrongPassword
    case userNotFound
    case emailAlreadyInUse
    case weakPassword
    case networkError
    case unknown(String)

    static func map(_ error: NSError) -> AuthError {
        switch AuthErrorCode(rawValue: error.code) {
        case .invalidEmail:        return .invalidEmail
        case .wrongPassword:       return .wrongPassword
        case .userNotFound:        return .userNotFound
        case .emailAlreadyInUse:   return .emailAlreadyInUse
        case .weakPassword:        return .weakPassword
        case .networkError:        return .networkError
        default:                   return .unknown(error.localizedDescription)
        }
    }

    var errorDescription: String? {
        switch self {
        case .invalidEmail:      return "Please enter a valid email address."
        case .wrongPassword:     return "Incorrect password. Please try again."
        case .userNotFound:      return "No account found with this email."
        case .emailAlreadyInUse: return "An account with this email already exists."
        case .weakPassword:      return "Password must be at least 8 characters."
        case .networkError:      return "Network error. Please check your connection."
        case .unknown(let msg):  return msg
        }
    }
}
