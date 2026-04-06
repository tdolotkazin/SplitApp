import UIKit

/*
final class DefaultViewControllerProvider: ViewControllerProvider {
    var rootViewController: UIViewController? {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = scene.windows.first else {
            return nil
        }
        return window.rootViewController
    }
}*/

final class DefaultViewControllerProvider: ViewControllerProvider {
    
    var rootViewController: UIViewController? {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = scene.windows.first else {
            return nil
        }
        
        return window.rootViewController
    }
    
    /*
     
     private func topViewController(from root: UIViewController) -> UIViewController {
     var top = root
     
     while let presented = top.presentedViewController {
     top = presented
     }
     
     if let nav = top as? UINavigationController {
     return nav.visibleViewController ?? nav
     }
     
     if let tab = top as? UITabBarController {
     return tab.selectedViewController ?? tab
     }
     
     return top
     }*/
}
