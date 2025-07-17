import UIKit

protocol AddCustomColorViewControllerDelegate: AnyObject {
    func didAddCustomColor(name: String, color: UIColor)
}

class AddCustomColorViewController: UIViewController, UITextFieldDelegate, UIColorPickerViewControllerDelegate {
    weak var delegate: AddCustomColorViewControllerDelegate?
    private var selectedColor: UIColor = .systemBlue

    private let nameTextField = UITextField()
    private let hexTextField = UITextField()
    private let colorPreview = UIView()
    private let colorPickerVC = UIColorPickerViewController()
    private let saveButton = UIButton(type: .system)
    private let cancelButton = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupUI()
    }

    private func setupUI() {
        nameTextField.placeholder = "Color name"
        nameTextField.borderStyle = .roundedRect
        nameTextField.delegate = self
        nameTextField.autocapitalizationType = .words

        hexTextField.placeholder = "Hex RGB (e.g. #FFAA00)"
        hexTextField.borderStyle = .roundedRect
        hexTextField.keyboardType = .asciiCapable
        hexTextField.delegate = self

        colorPreview.layer.cornerRadius = 16
        colorPreview.layer.borderWidth = 1
        colorPreview.layer.borderColor = UIColor.systemGray4.cgColor
        colorPreview.backgroundColor = selectedColor
        colorPreview.translatesAutoresizingMaskIntoConstraints = false

        colorPickerVC.selectedColor = selectedColor
        colorPickerVC.supportsAlpha = false
        colorPickerVC.delegate = self

        addChild(colorPickerVC)
        colorPickerVC.view.translatesAutoresizingMaskIntoConstraints = false
        colorPickerVC.view.layer.cornerRadius = 12
        colorPickerVC.view.layer.masksToBounds = true
        view.addSubview(colorPickerVC.view)
        colorPickerVC.didMove(toParent: self)

        saveButton.setTitle("Add", for: .normal)
        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        saveButton.tintColor = .systemBlue

        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        cancelButton.tintColor = .systemRed

        let stack = UIStackView(arrangedSubviews: [nameTextField, hexTextField, colorPreview, saveButton, cancelButton])
        stack.axis = .vertical
        stack.spacing = 16
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 32),
            stack.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.7),
            colorPreview.widthAnchor.constraint(equalToConstant: 32),
            colorPreview.heightAnchor.constraint(equalToConstant: 32),
            colorPickerVC.view.topAnchor.constraint(equalTo: stack.bottomAnchor, constant: 16),
            colorPickerVC.view.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            colorPickerVC.view.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.7),
            colorPickerVC.view.heightAnchor.constraint(equalToConstant: 350)
        ])
    }

    // Removed pickColorTapped, palette is now always visible

    func colorPickerViewControllerDidSelectColor(_ viewController: UIColorPickerViewController) {
        selectedColor = viewController.selectedColor
        colorPreview.backgroundColor = selectedColor
        hexTextField.text = selectedColor.toHexString
    }

    @objc private func saveTapped() {
        guard let name = nameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty else { return }
        var color = selectedColor
        if let hex = hexTextField.text, !hex.isEmpty {
            color = UIColor(hex: hex) ?? selectedColor
        }
        delegate?.didAddCustomColor(name: name, color: color)
        dismiss(animated: true)
    }

    @objc private func cancelTapped() {
        dismiss(animated: true)
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField == hexTextField, let hex = hexTextField.text, let color = UIColor(hex: hex) {
            selectedColor = color
            colorPreview.backgroundColor = color
        }
    }
}
