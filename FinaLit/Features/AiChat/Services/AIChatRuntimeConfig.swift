//
//  AIChatRuntimeConfig.swift
//  FinaLit
//
//  Created by Codex on 2/20/26.
//

import Foundation
import FirebaseAI

enum AIChatRuntimeConfig {
    // Gemini Developer API through Firebase AI Logic.
    static let backend: Backend = .googleAI()

    // Keep this in one place so model upgrades are one-line changes.
    static let modelName: String = "gemini-3-flash-preview"

    // If preview model is unavailable in the project, service auto-falls back.
    static let fallbackModelNames: [String] = [
        "gemini-2.5-flash",
        "gemini-2.0-flash"
    ]
}
