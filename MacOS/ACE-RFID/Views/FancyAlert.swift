import UIKit

class FancyAlert {
    struct AlertButton {
        let title: String
        let action: (() -> Void)?
        // Remove style property or set as needed, default system style is fine
    }

    static func show(
        on viewController: UIViewController,
        title: String,
        message: String,
        buttons: [AlertButton] = [AlertButton(title: "OK", action: nil)]
    ) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        for button in buttons {
            let action = UIAlertAction(title: button.title, style: .default) { _ in
                button.action?()
            }
            alert.addAction(action)
        }
        viewController.present(alert, animated: true)
    }

    static func dismissCustomAlert() {
        // No-op: UIAlertController handles its own dismissal
    }
}
