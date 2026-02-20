//
//  AuthPages.swift
//  FinaLit
//
//  Created by aplle on 2/18/26.
//


// AuthPages.swift
// Features/Auth/Navigation/

import SwiftUI

enum AuthPages: Coordinatable {

    case login
    case register
    case forgotPassword
    // case verifyEmail

    // MARK: - Identifiable
    var id: String {
        switch self {
        case .login:    return "auth.login"
        case .register: return "auth.register"
        case .forgotPassword: return "auth.forgotPassword"
        }
    }

    // MARK: - View
    @ViewBuilder
    var body: some View {
        switch self {
        case .login:    LoginView()
        case .register: RegisterView()
        case .forgotPassword: ForgotPasswordView()
        }
    }
}
