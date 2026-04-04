import Foundation
#if canImport(UIKit)
import UIKit

enum SocialAuthPresenter {
    @MainActor
    static func current() -> UIViewController? {
        let activeScene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first(where: { $0.activationState == .foregroundActive })

        let keyWindow = activeScene?.windows.first(where: \.isKeyWindow)
            ?? UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap(\.windows)
                .first(where: \.isKeyWindow)

        return keyWindow?.rootViewController?.topMostPresentedController
    }
}

private extension UIViewController {
    var topMostPresentedController: UIViewController {
        if let navigationController = self as? UINavigationController {
            return navigationController.visibleViewController?.topMostPresentedController ?? navigationController
        }

        if let tabBarController = self as? UITabBarController {
            return tabBarController.selectedViewController?.topMostPresentedController ?? tabBarController
        }

        if let presentedViewController {
            return presentedViewController.topMostPresentedController
        }

        return self
    }
}
#endif
