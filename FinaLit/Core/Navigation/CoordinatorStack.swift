//
//  CoordinatorStack.swift
//  FinaLit
//
//  Created by aplle on 2/18/26.
//


// CoordinatorStack.swift
// Core/Navigation/

import SwiftUI

struct CoordinatorStack<CoordinatorPage: Coordinatable>: View {
    let root: CoordinatorPage
        var onRegister: ((Coordinator<CoordinatorPage>) -> Void)? = nil

    init(_ root: CoordinatorPage, onRegister: ((Coordinator<CoordinatorPage>) -> Void)? = nil) {
            self.root = root
            self.onRegister = onRegister
        }

        @State private var coordinator = Coordinator<CoordinatorPage>()

        var body: some View {
            NavigationStack(path: $coordinator.path) {
                root
                    .navigationDestination(for: CoordinatorPage.self) { $0 }
                    .sheet(item: $coordinator.sheet) { $0 }
                    .fullScreenCover(item: $coordinator.fullScreenCover) { $0 }
            }
            .environment(coordinator)
            .onAppear {
                // Register this coordinator with AppCoordinator
                // so AppCoordinator can drive it from the outside
                onRegister?(coordinator)
            }
        }
}
