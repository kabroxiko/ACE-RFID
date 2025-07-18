import UIKit

class FancyAlert {
    private static var overlayKey: UInt8 = 0
    private static var currentViewController: UIViewController?

    struct AlertButton {
        let title: String
        let action: (() -> Void)?
        // Remove style property or set as needed, default system style is fine
    }

    static func show(
        on viewController: UIViewController,
        title: String,
        message: String,
        icon: UIImage? = UIImage(systemName: "exclamationmark.triangle"),
        buttons: [AlertButton] = [AlertButton(title: "OK", action: nil)]
    ) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)

        // Add icon if provided (using NSAttributedString for title)
        if let icon = icon {
            let attachment = NSTextAttachment()
            attachment.image = icon.withRenderingMode(.alwaysTemplate)
            let iconString = NSAttributedString(attachment: attachment)
            let titleString = NSMutableAttributedString(attributedString: iconString)
            titleString.append(NSAttributedString(string: "  " + title))
            alert.setValue(titleString, forKey: "attributedTitle")
        }

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
