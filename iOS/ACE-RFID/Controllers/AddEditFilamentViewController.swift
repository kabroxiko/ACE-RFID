//
//  AddEditFilamentViewController.swift
//  ACE-RFID
//
//  Created by Copilot on 07/03/2025.
//

import UIKit

protocol AddEditFilamentViewControllerDelegate: AnyObject {
    func didSaveFilament(_ filament: Filament)
}

class AddEditFilamentViewController: UIViewController {

    // MARK: - Properties

    weak var delegate: AddEditFilamentViewControllerDelegate?
    private var filament: Filament?
    private var isEditMode: Bool { return filament != nil }

    // MARK: - UI Elements

    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let stackView = UIStackView()

    // Form fields
    private let brandTextField = UITextField()
    private let brandPickerView = UIPickerView()
    private let materialPickerView = UIPickerView()
    private let colorTextField = UITextField()
    private let colorPickerView = UIPickerView()
    private let weightTextField = UITextField()
    private let diameterTextField = UITextField()
    private let printTemperatureTextField = UITextField()
    private let bedTemperatureTextField = UITextField()
    private let fanSpeedTextField = UITextField()
    private let printSpeedTextField = UITextField()
    private let notesTextView = UITextView()

    private let materialTextField = UITextField()

    // MARK: - Initialization

    init(filament: Filament? = nil) {
        self.filament = filament
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigationBar()
        fillFormWithFilament()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        registerKeyboardNotifications()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        unregisterKeyboardNotifications()
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = .systemBackground

        // Scroll view setup
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = true

        contentView.translatesAutoresizingMaskIntoConstraints = false

        // Stack view setup
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 20
        stackView.distribution = .fill

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(stackView)

        // Setup form fields
        setupFormFields()

        // Constraints
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

            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])
    }

    private func setupNavigationBar() {
        title = isEditMode ? "Edit Filament" : "Add Filament"

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(cancelTapped)
        )

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .save,
            target: self,
            action: #selector(saveTapped)
        )
    }

    private func setupFormFields() {
        // Brand section
        stackView.addArrangedSubview(createSectionLabel("Brand"))
        brandTextField.placeholder = "Select brand"
        brandTextField.inputView = brandPickerView
        brandPickerView.delegate = self
        brandPickerView.dataSource = self
        brandPickerView.tag = 0 // Tag to identify picker
        stackView.addArrangedSubview(createFormField(brandTextField))

        // Material section
        stackView.addArrangedSubview(createSectionLabel("Material"))
        materialTextField.placeholder = "Select material"
        materialTextField.inputView = materialPickerView
        materialPickerView.delegate = self
        materialPickerView.dataSource = self
        materialPickerView.tag = 1 // Tag to identify picker
        stackView.addArrangedSubview(createFormField(materialTextField))

        // Color section
        stackView.addArrangedSubview(createSectionLabel("Color"))
        colorTextField.placeholder = "Select color"
        colorTextField.inputView = colorPickerView
        colorPickerView.delegate = self
        colorPickerView.dataSource = self
        colorPickerView.tag = 2 // Tag to identify picker
        stackView.addArrangedSubview(createFormField(colorTextField))

        // Weight section
        stackView.addArrangedSubview(createSectionLabel("Weight (grams)"))
        weightTextField.placeholder = "1000"
        weightTextField.text = "1000" // Default value
        weightTextField.keyboardType = .decimalPad
        stackView.addArrangedSubview(createFormField(weightTextField))

        // Diameter section
        stackView.addArrangedSubview(createSectionLabel("Diameter (mm)"))
        diameterTextField.placeholder = "1.75"
        diameterTextField.text = "1.75" // Default value
        diameterTextField.keyboardType = .decimalPad
        stackView.addArrangedSubview(createFormField(diameterTextField))

        // Print temperature section
        stackView.addArrangedSubview(createSectionLabel("Print Temperature (°C)"))
        printTemperatureTextField.placeholder = "200"
        printTemperatureTextField.text = "200" // Default value
        printTemperatureTextField.keyboardType = .numberPad
        stackView.addArrangedSubview(createFormField(printTemperatureTextField))

        // Bed temperature section
        stackView.addArrangedSubview(createSectionLabel("Bed Temperature (°C)"))
        bedTemperatureTextField.placeholder = "60"
        bedTemperatureTextField.text = "60" // Default value
        bedTemperatureTextField.keyboardType = .numberPad
        stackView.addArrangedSubview(createFormField(bedTemperatureTextField))

        // Fan speed section
        stackView.addArrangedSubview(createSectionLabel("Fan Speed (%)"))
        fanSpeedTextField.placeholder = "100"
        fanSpeedTextField.text = "100" // Default value
        fanSpeedTextField.keyboardType = .numberPad
        stackView.addArrangedSubview(createFormField(fanSpeedTextField))

        // Print speed section
        stackView.addArrangedSubview(createSectionLabel("Print Speed (mm/s)"))
        printSpeedTextField.placeholder = "50"
        printSpeedTextField.text = "50" // Default value
        printSpeedTextField.keyboardType = .numberPad
        stackView.addArrangedSubview(createFormField(printSpeedTextField))

        // Notes section
        stackView.addArrangedSubview(createSectionLabel("Notes"))
        notesTextView.layer.borderColor = UIColor.systemGray4.cgColor
        notesTextView.layer.borderWidth = 1
        notesTextView.layer.cornerRadius = 8
        notesTextView.font = UIFont.systemFont(ofSize: 16)
        notesTextView.translatesAutoresizingMaskIntoConstraints = false
        notesTextView.heightAnchor.constraint(equalToConstant: 100).isActive = true
        stackView.addArrangedSubview(notesTextView)

        // Add toolbar to picker keyboards
        addToolbarToPickers()
        // Add toolbar to number pad keyboards
        addToolbarToKeyboard()
    }

    private func createSectionLabel(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = .label
        return label
    }

    private func createFormField(_ textField: UITextField) -> UIView {
        let containerView = UIView()
        containerView.backgroundColor = .secondarySystemBackground
        containerView.layer.cornerRadius = 8
        containerView.translatesAutoresizingMaskIntoConstraints = false

        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.font = .systemFont(ofSize: 16)
        textField.borderStyle = .none

        containerView.addSubview(textField)

        NSLayoutConstraint.activate([
            containerView.heightAnchor.constraint(equalToConstant: 44),
            textField.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            textField.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            textField.centerYAnchor.constraint(equalTo: containerView.centerYAnchor)
        ])

        return containerView
    }

    private func addToolbarToPickers() {
        let toolbar = UIToolbar()
        toolbar.sizeToFit()

        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissKeyboard))

        toolbar.items = [flexSpace, doneButton]

        brandTextField.inputAccessoryView = toolbar
        materialTextField.inputAccessoryView = toolbar
        colorTextField.inputAccessoryView = toolbar
    }

    private func addToolbarToKeyboard() {
        let toolbar = UIToolbar()
        toolbar.sizeToFit()

        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissKeyboard))

        toolbar.items = [flexSpace, doneButton]

        weightTextField.inputAccessoryView = toolbar
        diameterTextField.inputAccessoryView = toolbar
        printTemperatureTextField.inputAccessoryView = toolbar
        bedTemperatureTextField.inputAccessoryView = toolbar
        fanSpeedTextField.inputAccessoryView = toolbar
        printSpeedTextField.inputAccessoryView = toolbar
    }

    private func fillFormWithFilament() {
        guard let filament = filament else {
            // Set default values for new filament
            setDefaultValues()
            return
        }

        brandTextField.text = filament.brand
        materialTextField.text = filament.material
        colorTextField.text = filament.color
        weightTextField.text = String(filament.weight)
        diameterTextField.text = String(filament.diameter)
        printTemperatureTextField.text = String(filament.printTemperature)
        bedTemperatureTextField.text = String(filament.bedTemperature)
        fanSpeedTextField.text = String(filament.fanSpeed)
        printSpeedTextField.text = String(filament.printSpeed)
        notesTextView.text = filament.notes

        // Set picker views to correct selections
        if let brandIndex = Filament.Brand.allCases.firstIndex(where: { $0.rawValue == filament.brand }) {
            brandPickerView.selectRow(brandIndex, inComponent: 0, animated: false)
        }

        if let materialIndex = Filament.Material.allCases.firstIndex(where: { $0.rawValue == filament.material }) {
            materialPickerView.selectRow(materialIndex, inComponent: 0, animated: false)
        }

        if let colorIndex = Filament.Color.allCases.firstIndex(where: { $0.rawValue == filament.color }) {
            colorPickerView.selectRow(colorIndex, inComponent: 0, animated: false)
        }
    }

    private func setDefaultValues() {
        // Set default brand (first one - Anycubic)
        let defaultBrand = Filament.Brand.anycubic
        brandTextField.text = defaultBrand.rawValue
        brandPickerView.selectRow(0, inComponent: 0, animated: false)

        // Set default material (PLA)
        let defaultMaterial = Filament.Material.pla
        materialTextField.text = defaultMaterial.rawValue
        materialPickerView.selectRow(0, inComponent: 0, animated: false)

        // Set default color (Black)
        let defaultColor = Filament.Color.black
        colorTextField.text = defaultColor.rawValue
        colorPickerView.selectRow(0, inComponent: 0, animated: false)

        // Apply material-based defaults for temperatures and speeds
        printTemperatureTextField.text = String(defaultMaterial.defaultPrintTemperature)
        bedTemperatureTextField.text = String(defaultMaterial.defaultBedTemperature)
        fanSpeedTextField.text = String(defaultMaterial.defaultFanSpeed)
        printSpeedTextField.text = String(defaultMaterial.defaultPrintSpeed)
    }

    // MARK: - Actions

    @objc private func cancelTapped() {
        dismiss(animated: true)
    }

    @objc private func saveTapped() {
        guard validateForm() else { return }

        let brand = brandTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let material = materialTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let color = colorTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let weight = Double(weightTextField.text ?? "0") ?? 0
        let diameter = Double(diameterTextField.text ?? "1.75") ?? 1.75
        let printTemp = Int(printTemperatureTextField.text ?? "200") ?? 200
        let bedTemp = Int(bedTemperatureTextField.text ?? "60") ?? 60
        let fanSpeed = Int(fanSpeedTextField.text ?? "100") ?? 100
        let printSpeed = Int(printSpeedTextField.text ?? "50") ?? 50
        let notes = notesTextView.text?.trimmingCharacters(in: .whitespacesAndNewlines)

        if isEditMode {
            // Update existing filament
            var updatedFilament = filament!
            updatedFilament.brand = brand
            updatedFilament.material = material
            updatedFilament.color = color
            updatedFilament.weight = weight
            updatedFilament.diameter = diameter
            updatedFilament.printTemperature = printTemp
            updatedFilament.bedTemperature = bedTemp
            updatedFilament.fanSpeed = fanSpeed
            updatedFilament.printSpeed = printSpeed
            updatedFilament.notes = notes?.isEmpty == true ? nil : notes

            CoreDataManager.shared.updateFilament(updatedFilament)
            delegate?.didSaveFilament(updatedFilament)
        } else {
            // Create new filament
            let newFilament = Filament(
                brand: brand,
                material: material,
                color: color,
                weight: weight,
                diameter: diameter,
                printTemperature: printTemp,
                bedTemperature: bedTemp,
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

    // MARK: - Validation

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

        guard let weightText = weightTextField.text,
              let weight = Double(weightText),
              weight > 0 else {
            showAlert(title: "Invalid Weight", message: "Please enter a valid weight in grams.")
            return false
        }

        return true
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    // MARK: - Keyboard Handling

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
        scrollView.scrollIndicatorInsets.bottom = keyboardHeight
    }

    @objc private func keyboardWillHide(notification: NSNotification) {
        scrollView.contentInset.bottom = 0
        scrollView.scrollIndicatorInsets.bottom = 0
    }
}

// MARK: - UIPickerViewDataSource

extension AddEditFilamentViewController: UIPickerViewDataSource {

    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        switch pickerView.tag {
        case 0: // Brand picker
            return Filament.Brand.allCases.count
        case 1: // Material picker
            return Filament.Material.allCases.count
        case 2: // Color picker
            return Filament.Color.allCases.count
        default:
            return 0
        }
    }
}

// MARK: - UIPickerViewDelegate

extension AddEditFilamentViewController: UIPickerViewDelegate {

    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        if pickerView.tag == 2 { // Color picker
            let color = Filament.Color.allCases[row]

            let containerView = UIView()
            containerView.frame = CGRect(x: 0, y: 0, width: 200, height: 30)

            let colorIndicator = UIView()
            colorIndicator.backgroundColor = color.displayColor
            colorIndicator.layer.cornerRadius = 8
            colorIndicator.layer.borderWidth = 1
            colorIndicator.layer.borderColor = UIColor.systemGray4.cgColor
            colorIndicator.translatesAutoresizingMaskIntoConstraints = false

            let label = UILabel()
            label.text = color.rawValue
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

            return containerView
        } else {
            // For brand and material pickers, use default text
            let label = UILabel()
            label.textAlignment = .center
            label.font = UIFont.systemFont(ofSize: 17)
            label.textColor = .label

            switch pickerView.tag {
            case 0: // Brand picker
                label.text = Filament.Brand.allCases[row].rawValue
            case 1: // Material picker
                label.text = Filament.Material.allCases[row].rawValue
            default:
                label.text = ""
            }

            return label
        }
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        // This method is now only used as fallback for older iOS versions
        switch pickerView.tag {
        case 0: // Brand picker
            return Filament.Brand.allCases[row].rawValue
        case 1: // Material picker
            return Filament.Material.allCases[row].rawValue
        case 2: // Color picker
            return Filament.Color.allCases[row].rawValue
        default:
            return nil
        }
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        switch pickerView.tag {
        case 0: // Brand picker
            let selectedBrand = Filament.Brand.allCases[row]
            brandTextField.text = selectedBrand.rawValue

            // Update weight and diameter defaults when brand changes
            if weightTextField.text?.isEmpty ?? true || weightTextField.text == "1000" {
                weightTextField.text = String(selectedBrand.defaultWeight)
            }
            if diameterTextField.text?.isEmpty ?? true || diameterTextField.text == "1.75" {
                diameterTextField.text = String(selectedBrand.defaultDiameter)
            }

        case 1: // Material picker
            let selectedMaterial = Filament.Material.allCases[row]
            materialTextField.text = selectedMaterial.rawValue

            // Auto-fill temperature and speed defaults based on material
            printTemperatureTextField.text = String(selectedMaterial.defaultPrintTemperature)
            bedTemperatureTextField.text = String(selectedMaterial.defaultBedTemperature)
            fanSpeedTextField.text = String(selectedMaterial.defaultFanSpeed)
            printSpeedTextField.text = String(selectedMaterial.defaultPrintSpeed)

        case 2: // Color picker
            let selectedColor = Filament.Color.allCases[row]
            colorTextField.text = selectedColor.rawValue

        default:
            break
        }
    }
}
