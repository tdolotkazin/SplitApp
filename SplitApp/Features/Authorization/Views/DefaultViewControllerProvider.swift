import UIKit

final class DefaultViewControllerProvider: ViewControllerProvider {
    var rootViewController: UIViewController? {
        guard
            let scene = UIApplication.shared.connectedScenes.first
            as? UIWindowScene,
            let window = scene.windows.first
        else {
            return nil
        }

        return window.rootViewController
    }
}
