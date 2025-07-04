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
    private let materialPickerView = UIPickerView()
    private let colorTextField = UITextField()
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
        brandTextField.placeholder = "Enter brand name"
        stackView.addArrangedSubview(createFormField(brandTextField))

        // Material section
        stackView.addArrangedSubview(createSectionLabel("Material"))
        materialTextField.placeholder = "Select material"
        materialTextField.inputView = materialPickerView
        materialPickerView.delegate = self
        materialPickerView.dataSource = self
        stackView.addArrangedSubview(createFormField(materialTextField))

        // Color section
        stackView.addArrangedSubview(createSectionLabel("Color"))
        colorTextField.placeholder = "Enter color"
        stackView.addArrangedSubview(createFormField(colorTextField))

        // Weight section
        stackView.addArrangedSubview(createSectionLabel("Weight (grams)"))
        weightTextField.placeholder = "1000"
        weightTextField.keyboardType = .decimalPad
        stackView.addArrangedSubview(createFormField(weightTextField))

        // Diameter section
        stackView.addArrangedSubview(createSectionLabel("Diameter (mm)"))
        diameterTextField.placeholder = "1.75"
        diameterTextField.keyboardType = .decimalPad
        stackView.addArrangedSubview(createFormField(diameterTextField))

        // Print temperature section
        stackView.addArrangedSubview(createSectionLabel("Print Temperature (°C)"))
        printTemperatureTextField.placeholder = "200"
        printTemperatureTextField.keyboardType = .numberPad
        stackView.addArrangedSubview(createFormField(printTemperatureTextField))

        // Bed temperature section
        stackView.addArrangedSubview(createSectionLabel("Bed Temperature (°C)"))
        bedTemperatureTextField.placeholder = "60"
        bedTemperatureTextField.keyboardType = .numberPad
        stackView.addArrangedSubview(createFormField(bedTemperatureTextField))

        // Fan speed section
        stackView.addArrangedSubview(createSectionLabel("Fan Speed (%)"))
        fanSpeedTextField.placeholder = "100"
        fanSpeedTextField.keyboardType = .numberPad
        stackView.addArrangedSubview(createFormField(fanSpeedTextField))

        // Print speed section
        stackView.addArrangedSubview(createSectionLabel("Print Speed (mm/s)"))
        printSpeedTextField.placeholder = "50"
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
        guard let filament = filament else { return }

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

        // Set picker view to correct material
        if let materialIndex = Filament.Material.allCases.firstIndex(where: { $0.rawValue == filament.material }) {
            materialPickerView.selectRow(materialIndex, inComponent: 0, animated: false)
        }
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
        return Filament.Material.allCases.count
    }
}

// MARK: - UIPickerViewDelegate

extension AddEditFilamentViewController: UIPickerViewDelegate {

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return Filament.Material.allCases[row].rawValue
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let selectedMaterial = Filament.Material.allCases[row]
        materialTextField.text = selectedMaterial.rawValue

        // Auto-fill temperature defaults based on material
        if printTemperatureTextField.text?.isEmpty ?? true {
            printTemperatureTextField.text = String(selectedMaterial.defaultPrintTemperature)
        }

        if bedTemperatureTextField.text?.isEmpty ?? true {
            bedTemperatureTextField.text = String(selectedMaterial.defaultBedTemperature)
        }
    }
}
