import SwiftUI
import AuthenticationServices

struct AuthAppleSignInButton: View {
    @Environment(\.colorScheme) private var colorScheme

    let onRequest: (ASAuthorizationAppleIDRequest) -> Void
    let onCompletion: (Result<ASAuthorization, Error>) -> Void

    var body: some View {
        SignInWithAppleButton(.continue, onRequest: onRequest, onCompletion: onCompletion)
            .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}
