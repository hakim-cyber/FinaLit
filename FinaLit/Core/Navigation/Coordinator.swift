//
//  Coordinator.swift
//  FinaLit
//
//  Created by aplle on 2/18/26.
//



import SwiftUI

@Observable
final class Coordinator<CoordinatorPage: Coordinatable> {
    var path: NavigationPath = NavigationPath()
    var sheet: CoordinatorPage?
    var fullScreenCover: CoordinatorPage?

    enum PushType {
        case link
        case sheet
        case fullScreenCover
    }

    enum PopType {
        case link(last: Int = 1)
        case sheet
        case fullScreenCover
    }

    func push(_ page: CoordinatorPage, type: PushType = .link) {
        switch type {
        case .link:            path.append(page)
        case .sheet:           sheet = page
        case .fullScreenCover: fullScreenCover = page
        }
    }

    func pop(_ type: PopType = .link(last: 1)) {
        switch type {
        case .link(let last):  path.removeLast(min(last, path.count))
        case .sheet:           sheet = nil
        case .fullScreenCover: fullScreenCover = nil
        }
    }

    func popToRoot() {
        path.removeLast(path.count)
    }

    deinit {}
}
