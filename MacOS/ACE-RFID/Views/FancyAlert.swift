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
        let alertView = UIView()
        alertView.backgroundColor = UIColor.systemBackground
        alertView.layer.cornerRadius = 16
        alertView.layer.shadowColor = UIColor.black.cgColor
        alertView.layer.shadowOpacity = 0.2
        alertView.layer.shadowRadius = 8
        alertView.layer.shadowOffset = CGSize(width: 0, height: 4)
        alertView.translatesAutoresizingMaskIntoConstraints = false

        let iconImageView = UIImageView(image: icon)
        iconImageView.tintColor = .systemBlue
        iconImageView.translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        titleLabel.textColor = .label
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        let messageLabel = UILabel()
        messageLabel.text = message
        messageLabel.font = UIFont.systemFont(ofSize: 16)
        messageLabel.textColor = .secondaryLabel
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0
        messageLabel.translatesAutoresizingMaskIntoConstraints = false

        var buttonViews: [UIButton] = []
        for button in buttons {
            let btn = UIButton(type: .system)
            btn.setTitle(button.title, for: .normal)
            btn.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .medium)
            btn.tintColor = .systemBlue
            btn.translatesAutoresizingMaskIntoConstraints = false
            btn.addAction(UIAction { _ in
                FancyAlert.dismissCustomAlert()
                button.action?()
            }, for: .touchUpInside)
            alertView.addSubview(btn)
            buttonViews.append(btn)
        }

        alertView.addSubview(iconImageView)
        alertView.addSubview(titleLabel)
        alertView.addSubview(messageLabel)

        let overlay = UIView()
        overlay.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        overlay.translatesAutoresizingMaskIntoConstraints = false
        overlay.tag = 9999
        overlay.addSubview(alertView)
        viewController.view.addSubview(overlay)

        var constraints: [NSLayoutConstraint] = [
            overlay.leadingAnchor.constraint(equalTo: viewController.view.leadingAnchor),
            overlay.trailingAnchor.constraint(equalTo: viewController.view.trailingAnchor),
            overlay.topAnchor.constraint(equalTo: viewController.view.topAnchor),
            overlay.bottomAnchor.constraint(equalTo: viewController.view.bottomAnchor),

            alertView.centerXAnchor.constraint(equalTo: overlay.centerXAnchor),
            alertView.centerYAnchor.constraint(equalTo: overlay.centerYAnchor),
            alertView.widthAnchor.constraint(equalToConstant: 320),
            alertView.heightAnchor.constraint(greaterThanOrEqualToConstant: 200),

            iconImageView.topAnchor.constraint(equalTo: alertView.topAnchor, constant: 24),
            iconImageView.centerXAnchor.constraint(equalTo: alertView.centerXAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 40),
            iconImageView.heightAnchor.constraint(equalToConstant: 40),

            titleLabel.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: alertView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: alertView.trailingAnchor, constant: -16),

            messageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            messageLabel.leadingAnchor.constraint(equalTo: alertView.leadingAnchor, constant: 16),
            messageLabel.trailingAnchor.constraint(equalTo: alertView.trailingAnchor, constant: -16),
        ]
        // Stack buttons vertically, spacing 12 between each
        var previousAnchor: NSLayoutYAxisAnchor = messageLabel.bottomAnchor
        for btn in buttonViews {
            constraints.append(btn.topAnchor.constraint(equalTo: previousAnchor, constant: 20))
            constraints.append(btn.centerXAnchor.constraint(equalTo: alertView.centerXAnchor))
            previousAnchor = btn.bottomAnchor
        }
        constraints.append(previousAnchor.constraint(equalTo: alertView.bottomAnchor, constant: -16))
        NSLayoutConstraint.activate(constraints)

        alertView.alpha = 0
        UIView.animate(withDuration: 0.25) {
            alertView.alpha = 1
        }

        objc_setAssociatedObject(viewController, &FancyAlert.overlayKey, overlay, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        FancyAlert.currentViewController = viewController
    }

    static func dismissCustomAlert() {
        guard let viewController = FancyAlert.currentViewController else { return }
        if let overlay = objc_getAssociatedObject(viewController, &FancyAlert.overlayKey) as? UIView {
            UIView.animate(withDuration: 0.2, animations: {
                overlay.alpha = 0
            }, completion: { _ in
                overlay.removeFromSuperview()
            })
            objc_setAssociatedObject(viewController, &FancyAlert.overlayKey, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        FancyAlert.currentViewController = nil
    }
}
