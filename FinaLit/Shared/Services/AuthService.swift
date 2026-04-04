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
import FirebaseCore
import CryptoKit
import Security
#if canImport(UIKit)
import UIKit
#endif
#if canImport(GoogleSignIn)
@preconcurrency import GoogleSignIn
#endif

struct AuthenticatedIdentity {
    let uid: String
    let email: String
    let name: String
}

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
#if canImport(GoogleSignIn)
            GIDSignIn.sharedInstance.signOut()
#endif
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

    // MARK: - Social Sign-In

#if canImport(UIKit)
    @MainActor
    func signInWithGoogle(presenting presentingViewController: UIViewController) async throws -> AuthenticatedIdentity {
#if canImport(GoogleSignIn)
        guard let clientID = FirebaseApp.app()?.options.clientID, !clientID.isEmpty else {
            throw AuthError.missingGoogleClientID
        }

        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)

        do {
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController)

            guard let idToken = result.user.idToken?.tokenString else {
                throw AuthError.missingIdentityToken
            }

            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: result.user.accessToken.tokenString
            )

            let authResult = try await Auth.auth().signIn(with: credential)
            return try authenticatedIdentity(
                from: authResult.user,
                preferredEmail: result.user.profile?.email,
                preferredName: result.user.profile?.name
            )
        } catch let error as NSError {
            
            if let authError = error as? AuthError {
                throw authError
            }
            throw AuthError.unknown(error.localizedDescription)
        }
#else
        throw AuthError.providerUnavailable("Google Sign-In SDK is not installed.")
#endif
    }
#endif

    @MainActor
    func signInWithApple(
        idTokenString: String,
        rawNonce: String,
        fullName: PersonNameComponents?
    ) async throws -> AuthenticatedIdentity {
        let credential = OAuthProvider.appleCredential(
            withIDToken: idTokenString,
            rawNonce: rawNonce,
            fullName: fullName
        )

        do {
            let result = try await Auth.auth().signIn(with: credential)
            let formatter = PersonNameComponentsFormatter()
            let formattedName = fullName.flatMap { components in
                let rendered = formatter.string(from: components).trimmingCharacters(in: .whitespacesAndNewlines)
                return rendered.isEmpty ? nil : rendered
            }

            return try authenticatedIdentity(
                from: result.user,
                preferredEmail: result.user.email,
                preferredName: formattedName ?? result.user.displayName
            )
        } catch let error as NSError {
            throw AuthError.map(error)
        }
    }

    func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)

        let charset: [Character] =
        Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length

        while remainingLength > 0 {
            var randoms = [UInt8](repeating: 0, count: 16)
            let status = SecRandomCopyBytes(kSecRandomDefault, randoms.count, &randoms)

            if status != errSecSuccess {
                return UUID().uuidString.replacingOccurrences(of: "-", with: "")
            }

            randoms.forEach { random in
                if remainingLength == 0 {
                    return
                }

                if Int(random) < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }

        return result
    }

    func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.map { String(format: "%02x", $0) }.joined()
    }

    // MARK: - Sensitive Operation Guard

    /// Firebase account deletion often requires a very recent sign-in.
    /// We gate destructive client-side operations to avoid partial delete states.
    @MainActor
    func ensureRecentLoginForSensitiveOperation(maxAgeSeconds: TimeInterval = 900) async throws {
        guard let user = Auth.auth().currentUser else {
            throw AuthError.noAuthenticatedUser
        }

        guard let lastSignInDate = user.metadata.lastSignInDate else {
            throw AuthError.requiresRecentLogin
        }

        let age = Date().timeIntervalSince(lastSignInDate)
        guard age <= maxAgeSeconds else {
            throw AuthError.requiresRecentLogin
        }

        do {
            _ = try await user.getIDTokenResult(forcingRefresh: true)
        } catch let error as NSError {
            throw AuthError.map(error)
        }
    }

    // MARK: - Re-authentication

    @MainActor
    func reauthenticateCurrentUser(email: String, password: String) async throws {
        guard let user = Auth.auth().currentUser else {
            throw AuthError.noAuthenticatedUser
        }

        let credential = EmailAuthProvider.credential(
            withEmail: email,
            password: password
        )

        do {
            _ = try await user.reauthenticate(with: credential)
        } catch let error as NSError {
            throw AuthError.map(error)
        }
    }

    // MARK: - Delete Account

    @MainActor
    func deleteCurrentUser() async throws {
        guard let user = Auth.auth().currentUser else {
            throw AuthError.noAuthenticatedUser
        }

        do {
            try await user.delete()
        } catch let error as NSError {
            throw AuthError.map(error)
        }
    }

    deinit {
        if let authListener {
            Auth.auth().removeStateDidChangeListener(authListener)
        }
    }

    private func authenticatedIdentity(
        from user: FirebaseAuth.User,
        preferredEmail: String? = nil,
        preferredName: String? = nil
    ) throws -> AuthenticatedIdentity {
        let resolvedEmail = (preferredEmail ?? user.email)?
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let resolvedEmail, !resolvedEmail.isEmpty else {
            throw AuthError.missingProviderEmail
        }

        let cleanedPreferredName = preferredName?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let resolvedName: String
        if let cleanedPreferredName, !cleanedPreferredName.isEmpty {
            resolvedName = cleanedPreferredName
        } else if let displayName = user.displayName?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !displayName.isEmpty {
            resolvedName = displayName
        } else if let localPart = resolvedEmail.split(separator: "@").first,
                  !localPart.isEmpty {
            resolvedName = String(localPart)
        } else {
            resolvedName = "User"
        }

        return AuthenticatedIdentity(uid: user.uid, email: resolvedEmail, name: resolvedName)
    }
}

// MARK: - AuthError
// Maps Firebase NSError codes to readable app errors.
// Add cases as needed.

enum AuthError: LocalizedError, Equatable {
    case invalidEmail
    case wrongPassword
    case invalidCredential
    case userNotFound
    case emailAlreadyInUse
    case weakPassword
    case networkError
    case tooManyRequests
    case requiresRecentLogin
    case noAuthenticatedUser
    case missingGoogleClientID
    case missingIdentityToken
    case missingProviderEmail
    case invalidAppleCredential
    case unableToPresentSocialSignIn
    case providerUnavailable(String)
    case cancelled
    case unknown(String)

    static func map(_ error: NSError) -> AuthError {
        switch AuthErrorCode(rawValue: error.code) {
        case .invalidEmail:        return .invalidEmail
        case .wrongPassword:       return .wrongPassword
        case .invalidCredential:   return .invalidCredential
        case .userNotFound:        return .userNotFound
        case .emailAlreadyInUse:   return .emailAlreadyInUse
        case .weakPassword:        return .weakPassword
        case .networkError:        return .networkError
        case .tooManyRequests:     return .tooManyRequests
        case .requiresRecentLogin: return .requiresRecentLogin
        default:                   return .unknown(error.localizedDescription)
        }
    }

    var errorDescription: String? {
        switch self {
        case .invalidEmail:      return "Please enter a valid email address."
        case .wrongPassword:     return "Incorrect password. Please try again."
        case .invalidCredential: return "Incorrect credentials. Please try again."
        case .userNotFound:      return "No account found with this email."
        case .emailAlreadyInUse: return "An account with this email already exists."
        case .weakPassword:      return "Password must be at least 8 characters."
        case .networkError:      return "Network error. Please check your connection."
        case .tooManyRequests:   return "Too many attempts. Try again in a moment."
        case .requiresRecentLogin:
            return "Please confirm your password before deleting your account."
        case .noAuthenticatedUser:
            return "No active account session was found."
        case .missingGoogleClientID:
            return "Google Sign-In is not configured. Download a fresh GoogleService-Info.plist and add its URL scheme."
        case .missingIdentityToken:
            return "The identity provider did not return a valid sign-in token."
        case .missingProviderEmail:
            return "The sign-in provider did not return an email address."
        case .invalidAppleCredential:
            return "Apple Sign-In returned an invalid credential."
        case .unableToPresentSocialSignIn:
            return "Unable to open the sign-in sheet right now. Please try again."
        case .providerUnavailable(let message):
            return message
        case .cancelled:
            return nil
        case .unknown(let msg):  return msg
        }
    }
}
