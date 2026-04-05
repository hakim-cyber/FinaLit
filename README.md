# FinaLit

FinaLit is a production-oriented SwiftUI fintech application built as a freelance social-impact project.

It combines finance tracking, structured financial education, and AI-powered advisory workflows within a real-time architecture.
<img width="3887" height="2050" alt="IMG_0652 copy" src="https://github.com/user-attachments/assets/a90fb4fc-42e5-4fdf-b479-4ae5be31c4ac" />

<img width="3849" height="2052" alt="IMG_0652" src="https://github.com/user-attachments/assets/48aa1bcb-0287-42b3-9e69-0d50f35e7f63" />


## 🏗 Architecture Overview

### Architectural Style
- Hybrid MVVM + Coordinator
- Feature-based folder organization
- Service Layer abstraction
- Dependency Injection via constructor composition
- Protocol-based service boundaries
- Strongly typed navigation (generic `Coordinator<Page>`)

### Design Patterns Applied
- Model-View-ViewModel (MVVM)
- Coordinator Pattern
- Service Layer Pattern
- Dependency Injection Pattern
- Protocol-Oriented Programming
- Repository-style adapters
- Async Stream Bridging
- Derived State Pattern

---

## ⚙️ Concurrency & State Management

- Swift Concurrency (async/await, async let, Task)
- AsyncStream bridging for Firestore real-time updates
- MainActor isolation for UI safety
- Swift Observation (`@Observable`, `@Bindable`)
- Reactive root-flow switching based on authentication state

---

## ☁️ Backend & Persistence Stack

- Firebase Auth
- Firebase Firestore (real-time listeners)
- Firebase AI Logic (Gemini) with streaming responses
- SwiftData (local AI chat persistence)
- UserDefaults (AI consent state)
- Codable + Firestore `@DocumentID` models

---

## 📱 Technology Stack

- Swift 5
- SwiftUI
- NavigationStack
- Swift Concurrency
- SwiftData
- Firebase (Auth, Firestore, AI Logic)
- Swift Package Manager
- iOS 18 deployment target

---

## 🧠 Engineering Highlights

- Real-time financial analytics pipeline
- Derived insight generation engine
- AI streaming advisory subsystem
- Structured learning progression modeling
- Typed navigation architecture
- Performance-aware async orchestration
- Secure reauthentication gates for destructive actions

FinaLit demonstrates end-to-end architecture ownership and production-level SwiftUI system design.
