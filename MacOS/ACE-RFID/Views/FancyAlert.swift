import UIKit

class FancyAlert {
    private static var overlayKey: UInt8 = 0
    private static var currentViewController: UIViewController?

    static func show(on viewController: UIViewController, title: String, message: String, showSaveButton: Bool = false, saveAction: (() -> Void)? = nil) {
        let alertView = UIView()
        alertView.backgroundColor = UIColor.systemBackground
        alertView.layer.cornerRadius = 16
        alertView.layer.shadowColor = UIColor.black.cgColor
        alertView.layer.shadowOpacity = 0.2
        alertView.layer.shadowRadius = 8
        alertView.layer.shadowOffset = CGSize(width: 0, height: 4)
        alertView.translatesAutoresizingMaskIntoConstraints = false

        let iconImageView = UIImageView(image: UIImage(systemName: "radiowaves.left"))
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

        let closeButton = UIButton(type: .system)
        closeButton.setTitle("Close", for: .normal)
        closeButton.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        closeButton.tintColor = .systemRed
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.addAction(UIAction { _ in
            FancyAlert.dismissCustomAlert()
        }, for: .touchUpInside)

        alertView.addSubview(iconImageView)
        alertView.addSubview(titleLabel)
        alertView.addSubview(messageLabel)
        alertView.addSubview(closeButton)

        var saveButton: UIButton?
        if showSaveButton {
            let button = UIButton(type: .system)
            button.setTitle("Save as Filament", for: .normal)
            button.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .medium)
            button.tintColor = .systemBlue
            button.translatesAutoresizingMaskIntoConstraints = false
            button.addAction(UIAction { _ in
                FancyAlert.saveAsFilamentFromAlert()
            }, for: .touchUpInside)
            alertView.addSubview(button)
            saveButton = button
        }

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
        if let saveButton = saveButton {
            constraints.append(contentsOf: [
                saveButton.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 20),
                saveButton.centerXAnchor.constraint(equalTo: alertView.centerXAnchor),
                closeButton.topAnchor.constraint(equalTo: saveButton.bottomAnchor, constant: 12),
                closeButton.centerXAnchor.constraint(equalTo: alertView.centerXAnchor),
                closeButton.bottomAnchor.constraint(equalTo: alertView.bottomAnchor, constant: -16)
            ])
        } else {
            constraints.append(contentsOf: [
                closeButton.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 20),
                closeButton.centerXAnchor.constraint(equalTo: alertView.centerXAnchor),
                closeButton.bottomAnchor.constraint(equalTo: alertView.bottomAnchor, constant: -16)
            ])
        }
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

    static func saveAsFilamentFromAlert() {
        guard let viewController = FancyAlert.currentViewController as? MainViewController else { return }
        dismissCustomAlert()
        let addViewController = AddEditFilamentViewController()
        addViewController.delegate = viewController
        let navigationController = UINavigationController(rootViewController: addViewController)
        viewController.present(navigationController, animated: true)
    }
}
