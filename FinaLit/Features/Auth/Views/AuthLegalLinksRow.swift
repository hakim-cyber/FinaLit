//
//  AuthLegalLinksRow.swift
//  FinaLit
//

import SwiftUI

struct AuthLegalLinksRow: View {
    private var hasAnyLink: Bool {
        AppLegalLinks.privacyPolicyURL != nil || AppLegalLinks.termsOfUseURL != nil
    }

    var body: some View {
        if hasAnyLink {
            HStack(spacing: 16) {
                if let privacyPolicyURL = AppLegalLinks.privacyPolicyURL {
                    Link("Privacy Policy", destination: privacyPolicyURL)
                }

                if let termsOfUseURL = AppLegalLinks.termsOfUseURL {
                    Link("Terms of Use", destination: termsOfUseURL)
                }
            }
            .font(.system(size: 11, weight: .medium, design: .monospaced))
            .foregroundStyle(Color(hex: "6B7280"))
            .tint(Color(hex: "6B7280"))
            .frame(maxWidth: .infinity)
            .padding(.top, 2)
        }
    }
}
