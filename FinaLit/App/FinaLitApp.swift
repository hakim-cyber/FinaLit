//
//  FinaLitApp.swift
//  FinaLit
//
//  Created by aplle on 2/17/26.
//

import SwiftUI

import Firebase

@main
struct FinaLitApp: App {
    init(){
        FirebaseApp.configure()
                 
                
    }
    @State private var session = UserSession()
    @State private var appCoordinator = AppCoordinator()
    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(session)
                .environment(appCoordinator)     
        }
    }
}
