
import UIKit
// Custom UITextField subclass for dropdowns
class DropdownTextField: UITextField {
    override func caretRect(for position: UITextPosition) -> CGRect {
        return .zero // Hide caret
    }
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        return false // Disable copy/paste/select actions
    }
}
import Foundation

protocol AddEditFilamentViewControllerDelegate: AnyObject {
    func didSaveFilament(_ filament: Filament)
}

class AddEditFilamentViewController: UIViewController, UITextFieldDelegate, UIColorPickerViewControllerDelegate {
    private let brandTextField = DropdownTextField()
    private let materialTextField = DropdownTextField()
    private let colorTextField = DropdownTextField()
    private let weightTextField = DropdownTextField()
    private let diameterTextField = DropdownTextField()
    private let printTempMinTextField = DropdownTextField()
    private let printTempMaxTextField = DropdownTextField()
    private let bedTempMinTextField = DropdownTextField()
    private let bedTempMaxTextField = DropdownTextField()
    private let fanSpeedTextField = DropdownTextField()
    private let printSpeedTextField = DropdownTextField()
    private let notesTextView = UITextView()
    private var colorSwatchView: UIView? // For color swatch updates

    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let stackView = UIStackView()

    private enum TempFieldTag: Int {
        case printMin = 5
        case printMax = 6
        case bedMin = 7
        case bedMax = 8
        case fanSpeed = 9
        case printSpeed = 10
    }
    @objc private func showDropdown(_ sender: UITextField) {
        view.endEditing(true)
        let tag = dropdownTag(for: sender)
        let options: [String]
        switch tag {
        case 0:
            options = availableBrands
        case 1:
            options = Filament.Material.allCases.map { $0.rawValue }
        case 2:
            options = availableColors.map { $0.name }
        case 3:
            options = Filament.weightOptions.map { $0 < 1000 ? String(format: "%.0f g", $0) : String(format: "%.1f kg", $0 / 1000) }
        case 4:
            options = Filament.diameterOptions.map { String(format: "%.2f mm", $0) }
        case TempFieldTag.printMin.rawValue:
            options = Filament.temperatureMinOptions.map { "\($0)°C" }
        case TempFieldTag.printMax.rawValue:
            options = Filament.temperatureMaxOptions.map { "\($0)°C" }
        case TempFieldTag.bedMin.rawValue:
            options = Filament.bedMinTemperatureOptions.map { "\($0)°C" }
        case TempFieldTag.bedMax.rawValue:
            options = Filament.bedMaxTemperatureOptions.map { "\($0)°C" }
        case TempFieldTag.fanSpeed.rawValue:
            options = Filament.fanSpeedOptions.map { "\($0)%" }
        case TempFieldTag.printSpeed.rawValue:
            options = Filament.printSpeedOptions.map { "\($0) mm/s" }
        default:
            options = []
        }
        let dropdownVC = DropdownMenuController(options: options) { [weak self] selected in
            self?.handleDropdownSelection(selected, for: sender, tag: tag)
        }
        present(dropdownVC, animated: true)
    }

    private func dropdownTag(for textField: UITextField) -> Int {
        switch textField {
        case brandTextField: return 0
        case materialTextField: return 1
        case colorTextField: return 2
        case weightTextField: return 3
        case diameterTextField: return 4
        case printTempMinTextField: return TempFieldTag.printMin.rawValue
        case printTempMaxTextField: return TempFieldTag.printMax.rawValue
        case bedTempMinTextField: return TempFieldTag.bedMin.rawValue
        case bedTempMaxTextField: return TempFieldTag.bedMax.rawValue
        case fanSpeedTextField: return TempFieldTag.fanSpeed.rawValue
        case printSpeedTextField: return TempFieldTag.printSpeed.rawValue
        default: return -1
        }
    }

    private func handleDropdownSelection(_ selected: String, for textField: UITextField, tag: Int) {
        textField.text = selected
        if tag == 2 {
            if selected == "Add Custom Color..." {
                presentAddCustomColorView()
                return
            }
            if let color = availableColors.first(where: { $0.name == selected })?.color {
                updateColorSwatch(color)
            }
        }
        dismissKeyboard()
    }

    private func presentAddCustomColorView() {
        let customColorVC = AddCustomColorViewController()
        customColorVC.delegate = self
        customColorVC.modalPresentationStyle = .formSheet
        present(customColorVC, animated: true)
    }

    private let nfcService = NFCService()


    weak var delegate: AddEditFilamentViewControllerDelegate?
    var filament: Filament?
    private var isEditMode: Bool { return filament != nil }

    private lazy var availableBrands: [String] = {
        var brands = Filament.Brand.allCases.map { $0.rawValue }.sorted()
        brands.append("Add Custom Brand...")
        return brands
    }()

    private var customColorSelected: UIColor = .systemBlue

    private func showAddCustomColorAlert() {
    }

    private lazy var availableColors: [(name: String, color: UIColor)] = {
        var colors = Filament.FilamentColorType.allCases.map { ($0.rawValue, $0.displayColor) }
        colors.append((name: "Add Custom Color...", color: .clear))
        return colors
    }()

    private func fillFormWithFilament(_ filament: Filament) {
        brandTextField.text = filament.brand
        materialTextField.text = filament.material
        colorTextField.text = filament.color.name
        weightTextField.text = String(format: "%.0f", filament.length)
        diameterTextField.text = String(format: "%.2f", filament.diameter)
        printTempMinTextField.text = "\(filament.printMinTemperature)°C"
        printTempMaxTextField.text = "\(filament.printMaxTemperature)°C"
        bedTempMinTextField.text = "\(filament.bedMinTemperature)°C"
        bedTempMaxTextField.text = "\(filament.bedMaxTemperature)°C"
        fanSpeedTextField.text = "\(filament.fanSpeed)%"
        printSpeedTextField.text = "\(filament.printSpeed) mm/s"
        notesTextView.text = filament.notes
        updateColorSwatch(filament.color.uiColor ?? .systemBlue)
    }

    private func buildFilamentFromForm() -> Filament? {
        guard let sku = filament?.sku, !sku.isEmpty,
              let brand = brandTextField.text, !brand.isEmpty,
              let material = materialTextField.text, !material.isEmpty,
              let colorName = colorTextField.text, !colorName.isEmpty,
              let lengthStr = weightTextField.text, let length = Double(lengthStr),
              let diameterStr = diameterTextField.text, let diameter = Double(diameterStr),
              let printMinTempStr = printTempMinTextField.text?.replacingOccurrences(of: "°C", with: ""), let printMinTemp = Int(printMinTempStr),
              let printMaxTempStr = printTempMaxTextField.text?.replacingOccurrences(of: "°C", with: ""), let printMaxTemp = Int(printMaxTempStr),
              let bedMinTempStr = bedTempMinTextField.text?.replacingOccurrences(of: "°C", with: ""), let bedMinTemp = Int(bedMinTempStr),
              let bedMaxTempStr = bedTempMaxTextField.text?.replacingOccurrences(of: "°C", with: ""), let bedMaxTemp = Int(bedMaxTempStr),
              let fanSpeedStr = fanSpeedTextField.text?.replacingOccurrences(of: "%", with: ""), let fanSpeed = Int(fanSpeedStr),
              let printSpeedStr = printSpeedTextField.text?.replacingOccurrences(of: " mm/s", with: ""), let printSpeed = Int(printSpeedStr)
        else { return nil }

        let hex = availableColors.first(where: { $0.name == colorName })?.color.toHexString ?? UIColor.systemBlue.toHexString
        let colorObj = Color(name: colorName, hex: hex)

        return Filament(
            sku: sku,
            brand: brand,
            material: material,
            color: colorObj,
            length: length,
            diameter: diameter,
            printMinTemperature: printMinTemp,
            printMaxTemperature: printMaxTemp,
            bedMinTemperature: bedMinTemp,
            bedMaxTemperature: bedMaxTemp,
            fanSpeed: fanSpeed,
            printSpeed: printSpeed,
            notes: notesTextView.text
        )
    }


    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigationBar()
        fillFormWithFilament()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        registerKeyboardNotifications()
        refreshColors()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        unregisterKeyboardNotifications()
    }



    private func refreshColors() {
        let newColors = Filament.FilamentColorType.allCases.map { ($0.rawValue, $0.displayColor) }

        let hasChanged = newColors.count != availableColors.count ||
                        !zip(newColors, availableColors).allSatisfy { $0.0.0 == $0.1.0 }

        if hasChanged {
            availableColors = newColors
        }
    }


    private func setupUI() {
        view.backgroundColor = .systemBackground

        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [
            UIColor.systemBackground.cgColor,
            UIColor.secondarySystemBackground.cgColor
        ]
        gradientLayer.locations = [0, 1]
        view.layer.insertSublayer(gradientLayer, at: 0)

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            gradientLayer.frame = self.view.bounds
        }

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = true
        scrollView.alwaysBounceVertical = true
        scrollView.backgroundColor = .clear

        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.backgroundColor = .clear

        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 24 // Increased spacing for better visual hierarchy
        stackView.distribution = .fill

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(stackView)

        setupFormFields()

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 24),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24)
        ])
    }

    private func setupNavigationBar() {
        title = isEditMode ? "Edit Filament" : "Add Filament"

        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .automatic

        let cancelButton = UIBarButtonItem(
            title: "Cancel",
            style: .plain,
            target: self,
            action: #selector(cancelTapped)
        )
        cancelButton.tintColor = .systemRed
        navigationItem.leftBarButtonItem = cancelButton

        let saveButton = UIBarButtonItem(
            title: "Save",
            style: .done,
            target: self,
            action: #selector(saveTapped)
        )
        saveButton.tintColor = .systemBlue
        navigationItem.rightBarButtonItem = saveButton
    }

    private func setupFormFields() {
        stackView.addArrangedSubview(createSectionLabel("Brand"))
        brandTextField.placeholder = "Enter brand name or select from list"
        brandTextField.delegate = self
        stackView.addArrangedSubview(createFormField(brandTextField))

        materialTextField.placeholder = "Select material"
        materialTextField.delegate = self
        colorTextField.placeholder = "Select color"
        colorTextField.delegate = self
        stackView.addArrangedSubview(createSideBySideFormFields(materialTextField, leftLabel: "Material", colorTextField, rightLabel: "Color"))

        weightTextField.placeholder = "Select weight"
        weightTextField.delegate = self
        diameterTextField.placeholder = "Select diameter"
        diameterTextField.delegate = self
        stackView.addArrangedSubview(createSideBySideFormFields(weightTextField, leftLabel: "Weight", diameterTextField, rightLabel: "Diameter"))

        printTempMinTextField.placeholder = "Min"
        printTempMinTextField.delegate = self
        printTempMaxTextField.placeholder = "Max"
        printTempMaxTextField.delegate = self
        stackView.addArrangedSubview(createSideBySideFormFields(printTempMinTextField, leftLabel: "Print Temp Min", printTempMaxTextField, rightLabel: "Print Temp Max"))

        bedTempMinTextField.placeholder = "Min"
        bedTempMinTextField.delegate = self
        bedTempMaxTextField.placeholder = "Max"
        bedTempMaxTextField.delegate = self
        stackView.addArrangedSubview(createSideBySideFormFields(bedTempMinTextField, leftLabel: "Bed Temp Min", bedTempMaxTextField, rightLabel: "Bed Temp Max"))

        fanSpeedTextField.placeholder = "Select fan speed"
        fanSpeedTextField.delegate = self
        printSpeedTextField.placeholder = "Select print speed"
        printSpeedTextField.delegate = self
        stackView.addArrangedSubview(createSideBySideFormFields(fanSpeedTextField, leftLabel: "Fan Speed", printSpeedTextField, rightLabel: "Print Speed"))

        stackView.addArrangedSubview(createSectionLabel("Notes"))
        setupNotesTextView()
        stackView.addArrangedSubview(notesTextView)

        addToolbarToPickers()
    }

    private func setupNotesTextView() {
        notesTextView.backgroundColor = .tertiarySystemBackground
        notesTextView.layer.borderColor = UIColor.systemGray5.cgColor
        notesTextView.layer.borderWidth = 0.5
        notesTextView.layer.cornerRadius = 12
        notesTextView.font = UIFont.systemFont(ofSize: 16)
        notesTextView.textColor = .label
        notesTextView.translatesAutoresizingMaskIntoConstraints = false
        notesTextView.textContainerInset = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)

        notesTextView.layer.shadowColor = UIColor.black.cgColor
        notesTextView.layer.shadowOffset = CGSize(width: 0, height: 1)
        notesTextView.layer.shadowOpacity = 0.05
        notesTextView.layer.shadowRadius = 2

        notesTextView.heightAnchor.constraint(equalToConstant: 120).isActive = true
    }

    private func addToolbarToPickers() {
        let textFields = [
            brandTextField, materialTextField, colorTextField, weightTextField,
            diameterTextField, printTempMinTextField, printTempMaxTextField,
            bedTempMinTextField, bedTempMaxTextField, fanSpeedTextField,
            printSpeedTextField
        ]

        for textField in textFields {
            textField.inputAccessoryView = createInputToolbar()
        }

        notesTextView.inputAccessoryView = createInputToolbar()
    }

    private func createInputToolbar() -> UIToolbar {
        let toolbar = UIToolbar()
        toolbar.sizeToFit()

        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissKeyboard))

        toolbar.items = [flexSpace, doneButton]
        return toolbar
    }

    private func createSectionLabel(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 17, weight: .semibold)
        label.textColor = .systemBlue
        label.translatesAutoresizingMaskIntoConstraints = false

        label.heightAnchor.constraint(greaterThanOrEqualToConstant: 22).isActive = true

        return label
    }

    private func createFormField(_ textField: UITextField) -> UIView {
        let containerView = UIView()
        containerView.backgroundColor = .tertiarySystemBackground
        containerView.layer.cornerRadius = 12
        containerView.layer.borderWidth = 0.5
        containerView.layer.borderColor = UIColor.systemGray5.cgColor
        containerView.translatesAutoresizingMaskIntoConstraints = false

        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOffset = CGSize(width: 0, height: 1)
        containerView.layer.shadowOpacity = 0.05
        containerView.layer.shadowRadius = 2

        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.font = .systemFont(ofSize: 16, weight: .medium)
        textField.borderStyle = .none
        textField.isUserInteractionEnabled = true
        textField.tintColor = .clear // Hide text selection cursor
        textField.textColor = .label
        if #available(iOS 13.4, *) {
            addPointerInteraction(to: textField)
        }

        let dropdownImageView = UIImageView(image: UIImage(systemName: "chevron.down"))
        dropdownImageView.tintColor = .systemBlue
        dropdownImageView.contentMode = .scaleAspectFit
        dropdownImageView.translatesAutoresizingMaskIntoConstraints = false

        containerView.addSubview(textField)
        containerView.addSubview(dropdownImageView)

        NSLayoutConstraint.activate([
            containerView.heightAnchor.constraint(equalToConstant: 52), // Increased height for better touch targets
            textField.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            textField.trailingAnchor.constraint(equalTo: dropdownImageView.leadingAnchor, constant: -12),
            textField.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),

            dropdownImageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            dropdownImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            dropdownImageView.widthAnchor.constraint(equalToConstant: 18),
            dropdownImageView.heightAnchor.constraint(equalToConstant: 18)
        ])

        return containerView
    }

    private func createColorFormField(_ textField: UITextField) -> UIView {
        let containerView = UIView()
        containerView.backgroundColor = .tertiarySystemBackground
        containerView.layer.cornerRadius = 12
        containerView.layer.borderWidth = 0.5
        containerView.layer.borderColor = UIColor.systemGray5.cgColor
        containerView.translatesAutoresizingMaskIntoConstraints = false

        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOffset = CGSize(width: 0, height: 1)
        containerView.layer.shadowOpacity = 0.05
        containerView.layer.shadowRadius = 2

        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.font = .systemFont(ofSize: 16, weight: .medium)
        textField.borderStyle = .none
        textField.isUserInteractionEnabled = true
        textField.tintColor = .clear // Hide cursor since these are dropdown-style
        textField.textColor = .label
        if #available(iOS 13.4, *) {
            addPointerInteraction(to: textField)
        }

        let colorSwatchView = UIView()
        colorSwatchView.layer.cornerRadius = 12
        colorSwatchView.layer.borderWidth = 2
        colorSwatchView.layer.borderColor = UIColor.systemGray3.cgColor
        colorSwatchView.backgroundColor = .systemBlue // Default color
        colorSwatchView.translatesAutoresizingMaskIntoConstraints = false

        colorSwatchView.layer.shadowColor = UIColor.black.cgColor
        colorSwatchView.layer.shadowOffset = CGSize(width: 0, height: 1)
        colorSwatchView.layer.shadowOpacity = 0.3
        colorSwatchView.layer.shadowRadius = 2

        let dropdownImageView = UIImageView(image: UIImage(systemName: "chevron.down"))
        dropdownImageView.tintColor = .systemBlue
        dropdownImageView.contentMode = .scaleAspectFit
        dropdownImageView.translatesAutoresizingMaskIntoConstraints = false

        containerView.addSubview(colorSwatchView)
        containerView.addSubview(textField)
        containerView.addSubview(dropdownImageView)

        NSLayoutConstraint.activate([
            containerView.heightAnchor.constraint(equalToConstant: 52), // Increased height for better touch targets

            colorSwatchView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            colorSwatchView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            colorSwatchView.widthAnchor.constraint(equalToConstant: 24),
            colorSwatchView.heightAnchor.constraint(equalToConstant: 24),

            textField.leadingAnchor.constraint(equalTo: colorSwatchView.trailingAnchor, constant: 12),
            textField.trailingAnchor.constraint(equalTo: dropdownImageView.leadingAnchor, constant: -12),
            textField.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),

            dropdownImageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            dropdownImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            dropdownImageView.widthAnchor.constraint(equalToConstant: 18),
            dropdownImageView.heightAnchor.constraint(equalToConstant: 18)
        ])

        containerView.tag = 999 // Special tag to identify color field container
        colorSwatchView.tag = 1000 // Special tag to identify color swatch

        self.colorSwatchView = colorSwatchView

        return containerView
    }

    private func createSideBySideFormFields(_ leftField: UITextField, leftLabel: String, _ rightField: UITextField, rightLabel: String) -> UIView {
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false

        let horizontalStack = UIStackView()
        horizontalStack.axis = .horizontal
        horizontalStack.spacing = 16
        horizontalStack.distribution = .fillEqually
        horizontalStack.translatesAutoresizingMaskIntoConstraints = false

        let leftContainer = UIView()
        let leftLabelView = createFieldLabel(leftLabel)
        let leftFieldView = createFormField(leftField)

        leftContainer.addSubview(leftLabelView)
        leftContainer.addSubview(leftFieldView)
        leftContainer.translatesAutoresizingMaskIntoConstraints = false

        let rightContainer = UIView()
        let rightLabelView = createFieldLabel(rightLabel)
        let rightFieldView = rightField == colorTextField ? createColorFormField(rightField) : createFormField(rightField)

        rightContainer.addSubview(rightLabelView)
        rightContainer.addSubview(rightFieldView)
        rightContainer.translatesAutoresizingMaskIntoConstraints = false

        horizontalStack.addArrangedSubview(leftContainer)
        horizontalStack.addArrangedSubview(rightContainer)

        containerView.addSubview(horizontalStack)

        NSLayoutConstraint.activate([
            horizontalStack.topAnchor.constraint(equalTo: containerView.topAnchor),
            horizontalStack.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            horizontalStack.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            horizontalStack.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),

            leftLabelView.topAnchor.constraint(equalTo: leftContainer.topAnchor),
            leftLabelView.leadingAnchor.constraint(equalTo: leftContainer.leadingAnchor),
            leftLabelView.trailingAnchor.constraint(equalTo: leftContainer.trailingAnchor),

            leftFieldView.topAnchor.constraint(equalTo: leftLabelView.bottomAnchor, constant: 8),
            leftFieldView.leadingAnchor.constraint(equalTo: leftContainer.leadingAnchor),
            leftFieldView.trailingAnchor.constraint(equalTo: leftContainer.trailingAnchor),
            leftFieldView.bottomAnchor.constraint(equalTo: leftContainer.bottomAnchor),

            rightLabelView.topAnchor.constraint(equalTo: rightContainer.topAnchor),
            rightLabelView.leadingAnchor.constraint(equalTo: rightContainer.leadingAnchor),
            rightLabelView.trailingAnchor.constraint(equalTo: rightContainer.trailingAnchor),

            rightFieldView.topAnchor.constraint(equalTo: rightLabelView.bottomAnchor, constant: 8),
            rightFieldView.leadingAnchor.constraint(equalTo: rightContainer.leadingAnchor),
            rightFieldView.trailingAnchor.constraint(equalTo: rightContainer.trailingAnchor),
            rightFieldView.bottomAnchor.constraint(equalTo: rightContainer.bottomAnchor)
        ])

        return containerView
    }

    private func createFieldLabel(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }

    private func fillFormWithFilament() {
        guard let filament = filament else {
            setDefaultValues()
            return
        }

        brandTextField.text = filament.brand
        materialTextField.text = filament.material
        colorTextField.text = filament.color.name

        let weight = filament.convertedWeight
        if weight % 1000 == 0 {
            weightTextField.text = "\(weight / 1000) kg"
        } else {
            weightTextField.text = "\(weight) g"
        }

        diameterTextField.text = String(format: "%.2f mm", filament.diameter)
        printTempMinTextField.text = "\(filament.printMinTemperature)°C"
        printTempMaxTextField.text = "\(filament.printMaxTemperature)°C"
        bedTempMinTextField.text = "\(filament.bedMinTemperature)°C"
        bedTempMaxTextField.text = "\(filament.bedMaxTemperature)°C"
        printSpeedTextField.text = "\(filament.printSpeed) mm/s"
        notesTextView.text = filament.notes

        if let selectedColor = availableColors.first(where: { $0.name == filament.color.name })?.color {
            updateColorSwatch(selectedColor)
        }
    }

    private func setDefaultValues() {
        let defaultBrand = Filament.Brand.anycubic
        brandTextField.text = defaultBrand.rawValue

        let defaultMaterial = Filament.Material.pla
        materialTextField.text = defaultMaterial.rawValue

        let defaultColor = Filament.FilamentColorType.black
        colorTextField.text = defaultColor.rawValue
        updateColorSwatch(defaultColor.displayColor)

        let defaultWeight = defaultBrand.defaultWeight
        weightTextField.text = defaultWeight < 1000 ? String(format: "%.0f g", defaultWeight) : String(format: "%.1f kg", defaultWeight / 1000)

        let defaultDiameter = defaultBrand.defaultDiameter
        diameterTextField.text = String(format: "%.2f mm", defaultDiameter)

        let printMinTemp = defaultMaterial.defaultMinPrintTemperature
        let printMaxTemp = defaultMaterial.defaultMaxPrintTemperature
        let bedMinTemp = defaultMaterial.defaultMinBedTemperature
        let bedMaxTemp = defaultMaterial.defaultMaxBedTemperature
        let fanSpeed = defaultMaterial.defaultFanSpeed
        let printSpeed = defaultMaterial.defaultPrintSpeed

        printTempMinTextField.text = "\(printMinTemp)°C"
        printTempMaxTextField.text = "\(printMaxTemp)°C"
        bedTempMinTextField.text = "\(bedMinTemp)°C"
        bedTempMaxTextField.text = "\(bedMaxTemp)°C"
        fanSpeedTextField.text = "\(fanSpeed)%"
        printSpeedTextField.text = "\(printSpeed) mm/s"

    }

    private func initializeBrands() {
        availableBrands = Filament.Brand.sortedCases.map { $0.rawValue }
        availableBrands.append("Add Custom Brand...")
    }


    @objc private func cancelTapped() {
        dismiss(animated: true)
    }

    @objc private func saveTapped() {
        guard validateForm() else { return }

        let sku = filament?.sku ?? ""
        let brand = brandTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let material = materialTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let colorName = colorTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let hex = availableColors.first(where: { $0.name == colorName })?.color.toHexString ?? UIColor.systemBlue.toHexString
        let colorObj = Color(name: colorName, hex: hex)

        let weightText = weightTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "1000"
        var length: Double = 0
        // If editing, use filament.convertedWeight to get the weight, then convert back to length
        if let filament = filament {
            let weight = filament.convertedWeight
            // Use lookup table: 1kg = 330m, 500g = 165m
            if weight % 1000 == 0 {
                length = (Double(weight) / 1000) * 330
            } else if weight >= 500 {
                length = (Double(weight) / 500) * 165
            } else {
                length = (Double(weight) / 500) * 165
            }
        } else {
            // If not editing, parse from weightText
            if weightText.contains("kg") {
                let kgString = weightText.replacingOccurrences(of: "kg", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                if let kg = Double(kgString) {
                    length = kg * 330
                }
            } else if weightText.contains("g") {
                let gString = weightText.replacingOccurrences(of: "g", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                if let g = Double(gString) {
                    if g >= 1000 {
                        length = (g / 1000) * 330
                    } else if g >= 500 {
                        length = (g / 500) * 165
                    } else {
                        length = (g / 500) * 165
                    }
                }
            } else {
                length = Double(weightText) ?? 0
            }
        }

        let diameterText = diameterTextField.text ?? "1.75"
        let diameterString = diameterText.replacingOccurrences(of: " mm", with: "")
        let diameter = Double(diameterString) ?? 1.75

        let printMinTempText = printTempMinTextField.text ?? "180"
        let printMinTempString = printMinTempText.replacingOccurrences(of: "°C", with: "")
        let printMinTemp = Int(printMinTempString) ?? 180

        let printMaxTempText = printTempMaxTextField.text ?? "210"
        let printMaxTempString = printMaxTempText.replacingOccurrences(of: "°C", with: "")
        let printMaxTemp = Int(printMaxTempString) ?? 210

        let bedMinTempText = bedTempMinTextField.text ?? "50"
        let bedMinTempString = bedMinTempText.replacingOccurrences(of: "°C", with: "")
        let bedMinTemp = Int(bedMinTempString) ?? 50

        let bedMaxTempText = bedTempMaxTextField.text ?? "60"
        let bedMaxTempString = bedMaxTempText.replacingOccurrences(of: "°C", with: "")
        let bedMaxTemp = Int(bedMaxTempString) ?? 60

        let fanSpeedText = fanSpeedTextField.text ?? "100"
        let fanSpeedString = fanSpeedText.replacingOccurrences(of: "%", with: "")
        let fanSpeed = Int(fanSpeedString) ?? 100

        let printSpeedText = printSpeedTextField.text ?? "50"
        let printSpeedString = printSpeedText.replacingOccurrences(of: " mm/s", with: "")
        let printSpeed = Int(printSpeedString) ?? 50

        let notes = notesTextView.text?.trimmingCharacters(in: .whitespacesAndNewlines)

        if isEditMode {
            var updatedFilament = filament!

            updatedFilament.brand = brand
            updatedFilament.material = material
            updatedFilament.color = colorObj
            updatedFilament.length = length
            updatedFilament.diameter = diameter
            updatedFilament.printMinTemperature = printMinTemp
            updatedFilament.printMaxTemperature = printMaxTemp
            updatedFilament.bedMinTemperature = bedMinTemp
            updatedFilament.bedMaxTemperature = bedMaxTemp
            updatedFilament.fanSpeed = fanSpeed
            updatedFilament.printSpeed = printSpeed
            updatedFilament.notes = notes?.isEmpty == true ? nil : notes

            CoreDataManager.shared.updateFilament(updatedFilament)
            delegate?.didSaveFilament(updatedFilament)
        } else {
            let newFilament = Filament(
                sku: sku,
                brand: brand,
                material: material,
                color: colorObj,
                length: length,
                diameter: diameter,
                printMinTemperature: printMinTemp,
                printMaxTemperature: printMaxTemp,
                bedMinTemperature: bedMinTemp,
                bedMaxTemperature: bedMaxTemp,
                fanSpeed: fanSpeed,
                printSpeed: printSpeed,
                notes: notes?.isEmpty == true ? nil : notes
            )

            CoreDataManager.shared.saveFilament(newFilament)
            delegate?.didSaveFilament(newFilament)
        }

        dismiss(animated: true)
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }


    private func validateForm() -> Bool {
        guard let brand = brandTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !brand.isEmpty else {
            showAlert(title: "Invalid Brand", message: "Please enter a brand name.")
            return false
        }

        guard let material = materialTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !material.isEmpty else {
            showAlert(title: "Invalid Material", message: "Please select a material.")
            return false
        }

        guard let color = colorTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !color.isEmpty else {
            showAlert(title: "Invalid Color", message: "Please enter a color.")
            return false
        }

        return true
    }

    private func showAlert(title: String, message: String) {
        let okButton = FancyAlert.AlertButton(title: "OK", action: nil)
        FancyAlert.show(
            on: self,
            title: title,
            message: message,
            buttons: [okButton]
        )
    }

    private func updateColorSwatch(_ color: UIColor) {
        colorSwatchView?.backgroundColor = color
    }


    private func showAddCustomBrandAlert() {
        let alertVC = UIViewController()
        alertVC.preferredContentSize = CGSize(width: 300, height: 140)
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false

        let label = UILabel()
        label.text = "Enter the name of the filament brand"
        label.font = .systemFont(ofSize: 16)
        label.textAlignment = .center
        label.numberOfLines = 2

        let textField = UITextField()
        textField.placeholder = "Brand name"
        textField.autocapitalizationType = .words
        textField.borderStyle = .roundedRect
        textField.translatesAutoresizingMaskIntoConstraints = false

        stack.addArrangedSubview(label)
        stack.addArrangedSubview(textField)
        alertVC.view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: alertVC.view.topAnchor, constant: 24),
            stack.leadingAnchor.constraint(equalTo: alertVC.view.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: alertVC.view.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: alertVC.view.bottomAnchor, constant: -24)
        ])

        let addButton = FancyAlert.AlertButton(title: "Add", action: { [weak self] in
            guard let self = self,
                  let brandName = textField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !brandName.isEmpty else { return }
            if !self.availableBrands.contains(brandName) {
                self.availableBrands.insert(brandName, at: self.availableBrands.count - 1)
            }
            self.brandTextField.text = brandName
            self.dismissKeyboard()
            alertVC.dismiss(animated: true)
        })
        let cancelButton = FancyAlert.AlertButton(title: "Cancel", action: { [weak alertVC] in
            alertVC?.dismiss(animated: true)
        })
        let alert = UIAlertController(title: "Add Custom Brand", message: nil, preferredStyle: .alert)
        alert.setValue(alertVC, forKey: "contentViewController")
        alert.addAction(UIAlertAction(title: "Add", style: .default) { _ in addButton.action?() })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in cancelButton.action?() })
        present(alert, animated: true)
    }


    private func registerKeyboardNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }

    private func unregisterKeyboardNotifications() {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func keyboardWillShow(notification: NSNotification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }

        let keyboardHeight = keyboardFrame.height
        scrollView.contentInset.bottom = keyboardHeight
        if #available(iOS 13.0, *) {
            scrollView.verticalScrollIndicatorInsets.bottom = keyboardHeight
        } else {
            scrollView.scrollIndicatorInsets.bottom = keyboardHeight
        }
    }

    @objc private func keyboardWillHide(notification: NSNotification) {
        scrollView.contentInset.bottom = 0
        if #available(iOS 13.0, *) {
            scrollView.verticalScrollIndicatorInsets.bottom = 0
        } else {
            scrollView.scrollIndicatorInsets.bottom = 0
        }
    }
}


extension AddEditFilamentViewController: UIPickerViewDataSource {

    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        switch pickerView.tag {
        case 0: // Brand picker
            return availableBrands.count
        case 1: // Material picker
            return Filament.Material.allCases.count
        case 2: // Color picker
            return availableColors.count
        case 3: // Length picker
            return Filament.weightOptions.count
        case 4: // Diameter picker
            return Filament.diameterOptions.count
        case 5: // Print min temperature picker
            return Filament.temperatureMinOptions.count
        case 6: // Print max temperature picker
            return Filament.temperatureMaxOptions.count
        case 7: // Bed min temperature picker
            return Filament.bedMinTemperatureOptions.count
        case 8: // Bed max temperature picker
            return Filament.bedMaxTemperatureOptions.count
        case 9: // Fan speed picker
            return Filament.fanSpeedOptions.count
        case 10: // Print speed picker
            return Filament.printSpeedOptions.count
        default:
            return 0
        }
    }
}


extension AddEditFilamentViewController: UIPickerViewDelegate {

    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        if pickerView.tag == 2 { // Color picker
            let containerView: UIView
            let colorIndicator: UIView
            let label: UILabel

            if let reusableView = view {
                containerView = reusableView
                colorIndicator = containerView.subviews[0]
                label = containerView.subviews[1] as! UILabel
            } else {
                containerView = UIView()
                containerView.frame = CGRect(x: 0, y: 0, width: 200, height: 30)

                colorIndicator = UIView()
                colorIndicator.layer.cornerRadius = 8
                colorIndicator.layer.borderWidth = 1
                colorIndicator.layer.borderColor = UIColor.systemGray4.cgColor
                colorIndicator.translatesAutoresizingMaskIntoConstraints = false

                label = UILabel()
                label.font = UIFont.systemFont(ofSize: 17)
                label.textColor = .label
                label.translatesAutoresizingMaskIntoConstraints = false

                containerView.addSubview(colorIndicator)
                containerView.addSubview(label)

                NSLayoutConstraint.activate([
                    colorIndicator.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
                    colorIndicator.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
                    colorIndicator.widthAnchor.constraint(equalToConstant: 16),
                    colorIndicator.heightAnchor.constraint(equalToConstant: 16),

                    label.leadingAnchor.constraint(equalTo: colorIndicator.trailingAnchor, constant: 12),
                    label.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
                    label.centerYAnchor.constraint(equalTo: containerView.centerYAnchor)
                ])
            }

            let colorInfo = availableColors[row]
            colorIndicator.backgroundColor = colorInfo.color
            label.text = colorInfo.name

            return containerView
        } else {
            let label: UILabel
            if let reusableView = view as? UILabel {
                label = reusableView
            } else {
                label = UILabel()
                label.textAlignment = .center
                label.font = UIFont.systemFont(ofSize: 17)
                label.textColor = .label
            }

            switch pickerView.tag {
            case 0: // Brand picker
                label.text = availableBrands[row]
            case 1: // Material picker
                label.text = Filament.Material.allCases[row].rawValue
            case 3: // Weight picker
                let weight = Filament.weightOptions[row]
                label.text = weight < 1000 ? String(format: "%.0f g", weight) : String(format: "%.1f kg", weight / 1000)
            case 4: // Diameter picker
                label.text = String(format: "%.2f mm", Filament.diameterOptions[row])
            case 5: // Print Min temperature picker
                label.text = "\(Filament.temperatureMinOptions[row])°C"
            case 6: // Print Max temperature picker
                label.text = "\(Filament.temperatureMaxOptions[row])°C"
            case 7: // Bed Min temperature picker
                label.text = "\(Filament.bedMinTemperatureOptions[row])°C"
            case 8: // Bed Max temperature picker
                label.text = "\(Filament.bedMaxTemperatureOptions[row])°C"
            case 9: // Fan speed picker
                label.text = "\(Filament.fanSpeedOptions[row])%"
            case 10: // Print speed picker
                label.text = "\(Filament.printSpeedOptions[row]) mm/s"
            default:
                label.text = ""
            }

            return label
        }
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        switch pickerView.tag {
        case 0: // Brand picker
            return availableBrands[row]
        case 1: // Material picker
            return Filament.Material.allCases[row].rawValue
        case 2: // Color picker
            return availableColors[row].name
        default:
            return nil
        }
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
    }

    @available(iOS 13.4, *)
    private func addPointerInteraction(to textField: UITextField) {
        let pointerInteraction = UIPointerInteraction(delegate: self)
        textField.addInteraction(pointerInteraction)
    }
}

@available(iOS 13.4, *)
extension AddEditFilamentViewController: UIPointerInteractionDelegate {
    func pointerInteraction(_ interaction: UIPointerInteraction, styleFor region: UIPointerRegion) -> UIPointerStyle? {
        guard let view = interaction.view else { return nil }
        let targetedPreview = UITargetedPreview(view: view)
        return UIPointerStyle(effect: .highlight(targetedPreview))
    }
}


extension AddEditFilamentViewController {

    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        let dropdownFields: [UITextField] = [
            brandTextField, materialTextField, colorTextField, weightTextField,
            diameterTextField, printTempMinTextField, printTempMaxTextField,
            bedTempMinTextField, bedTempMaxTextField, fanSpeedTextField,
            printSpeedTextField
        ]
        if dropdownFields.contains(textField) {
            showDropdown(textField)
            return false // Prevent keyboard
        }
        return true
    }
    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField == brandTextField {
            guard let brandName = textField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !brandName.isEmpty else { return }

            if !availableBrands.contains(brandName) && brandName != "Add Custom Brand..." {
                availableBrands.insert(brandName, at: availableBrands.count - 1)
            }
        }
    }
}


// MARK: - AddCustomColorViewControllerDelegate
extension AddEditFilamentViewController: AddCustomColorViewControllerDelegate {
    func didAddCustomColor(name: String, color: UIColor) {
        if let idx = availableColors.firstIndex(where: { $0.name == "Add Custom Color..." }) {
            availableColors.remove(at: idx)
        }
        availableColors.append((name: name, color: color))
        availableColors.append((name: "Add Custom Color...", color: .clear))
        colorTextField.text = name
        updateColorSwatch(color)
    }
}
