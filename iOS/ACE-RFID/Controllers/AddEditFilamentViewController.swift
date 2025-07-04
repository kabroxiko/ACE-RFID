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

class AddEditFilamentViewController: UIViewController, UITextFieldDelegate {

    // MARK: - Properties

    weak var delegate: AddEditFilamentViewControllerDelegate?
    private var filament: Filament?
    private var isEditMode: Bool { return filament != nil }

    // Brand management
    private var availableBrands: [String] = []

    // Color management
    private var availableColors: [(name: String, color: UIColor)] = []

    // MARK: - UI Elements

    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let stackView = UIStackView()

    // Form fields
    private let brandTextField = UITextField()
    private let brandPickerView = UIPickerView()
    private let materialTextField = UITextField()
    private let materialPickerView = UIPickerView()
    private let colorTextField = UITextField()
    private let colorPickerView = UIPickerView()
    private let weightTextField = UITextField()
    private let weightPickerView = UIPickerView()
    private let diameterTextField = UITextField()
    private let diameterPickerView = UIPickerView()
    private let printTemperatureTextField = UITextField()
    private let printTemperaturePickerView = UIPickerView()
    private let bedTemperatureTextField = UITextField()
    private let bedTemperaturePickerView = UIPickerView()
    private let fanSpeedTextField = UITextField()
    private let fanSpeedPickerView = UIPickerView()
    private let printSpeedTextField = UITextField()
    private let printSpeedPickerView = UIPickerView()
    private let notesTextView = UITextView()

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
        initializeBrands()
        initializeColors()
        setupUI()
        setupNavigationBar()
        fillFormWithFilament()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        registerKeyboardNotifications()
        // Refresh colors in case custom colors were added elsewhere
        refreshColors()
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
        brandTextField.placeholder = "Enter brand name or select from list"
        brandTextField.inputView = brandPickerView
        brandTextField.delegate = self // Add text field delegate
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
        weightTextField.placeholder = "Select weight"
        weightTextField.text = "1000" // Default value
        weightTextField.inputView = weightPickerView
        weightPickerView.delegate = self
        weightPickerView.dataSource = self
        weightPickerView.tag = 3 // Tag to identify picker
        stackView.addArrangedSubview(createFormField(weightTextField))

        // Diameter section
        stackView.addArrangedSubview(createSectionLabel("Diameter (mm)"))
        diameterTextField.placeholder = "Select diameter"
        diameterTextField.text = "1.75" // Default value
        diameterTextField.inputView = diameterPickerView
        diameterPickerView.delegate = self
        diameterPickerView.dataSource = self
        diameterPickerView.tag = 4 // Tag to identify picker
        stackView.addArrangedSubview(createFormField(diameterTextField))

        // Print temperature section
        stackView.addArrangedSubview(createSectionLabel("Print Temperature (°C)"))
        printTemperatureTextField.placeholder = "Select temperature"
        printTemperatureTextField.text = "200" // Default value
        printTemperatureTextField.inputView = printTemperaturePickerView
        printTemperaturePickerView.delegate = self
        printTemperaturePickerView.dataSource = self
        printTemperaturePickerView.tag = 5 // Tag to identify picker
        stackView.addArrangedSubview(createFormField(printTemperatureTextField))

        // Bed temperature section
        stackView.addArrangedSubview(createSectionLabel("Bed Temperature (°C)"))
        bedTemperatureTextField.placeholder = "Select temperature"
        bedTemperatureTextField.text = "60" // Default value
        bedTemperatureTextField.inputView = bedTemperaturePickerView
        bedTemperaturePickerView.delegate = self
        bedTemperaturePickerView.dataSource = self
        bedTemperaturePickerView.tag = 6 // Tag to identify picker
        stackView.addArrangedSubview(createFormField(bedTemperatureTextField))

        // Fan speed section
        stackView.addArrangedSubview(createSectionLabel("Fan Speed (%)"))
        fanSpeedTextField.placeholder = "Select fan speed"
        fanSpeedTextField.text = "100" // Default value
        fanSpeedTextField.inputView = fanSpeedPickerView
        fanSpeedPickerView.delegate = self
        fanSpeedPickerView.dataSource = self
        fanSpeedPickerView.tag = 7 // Tag to identify picker
        stackView.addArrangedSubview(createFormField(fanSpeedTextField))

        // Print speed section
        stackView.addArrangedSubview(createSectionLabel("Print Speed (mm/s)"))
        printSpeedTextField.placeholder = "Select print speed"
        printSpeedTextField.text = "50" // Default value
        printSpeedTextField.inputView = printSpeedPickerView
        printSpeedPickerView.delegate = self
        printSpeedPickerView.dataSource = self
        printSpeedPickerView.tag = 8 // Tag to identify picker
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

        // All form fields now use pickers, so only add toolbar to text view
        notesTextView.inputAccessoryView = toolbar
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

        // Format weight display
        let weight = filament.weight
        weightTextField.text = weight < 1000 ? String(format: "%.0f g", weight) : String(format: "%.1f kg", weight / 1000)

        // Format other fields
        diameterTextField.text = String(format: "%.2f mm", filament.diameter)
        printTemperatureTextField.text = "\(filament.printTemperature)°C"
        bedTemperatureTextField.text = "\(filament.bedTemperature)°C"
        fanSpeedTextField.text = "\(filament.fanSpeed)%"
        printSpeedTextField.text = "\(filament.printSpeed) mm/s"
        notesTextView.text = filament.notes

        // Set picker views to correct selections
        if let brandIndex = availableBrands.firstIndex(of: filament.brand) {
            brandPickerView.selectRow(brandIndex, inComponent: 0, animated: false)
        } else {
            // Add custom brand if not in list
            availableBrands.insert(filament.brand, at: availableBrands.count - 1)
            brandPickerView.reloadAllComponents()
            if let brandIndex = availableBrands.firstIndex(of: filament.brand) {
                brandPickerView.selectRow(brandIndex, inComponent: 0, animated: false)
            }
        }

        if let materialIndex = Filament.Material.allCases.firstIndex(where: { $0.rawValue == filament.material }) {
            materialPickerView.selectRow(materialIndex, inComponent: 0, animated: false)
        }

        if let colorIndex = availableColors.firstIndex(where: { $0.name == filament.color }) {
            colorPickerView.selectRow(colorIndex, inComponent: 0, animated: false)
        }

        // Set weight picker selection
        if let weightIndex = Filament.weightOptions.firstIndex(of: weight) {
            weightPickerView.selectRow(weightIndex, inComponent: 0, animated: false)
        }

        // Set diameter picker selection
        if let diameterIndex = Filament.diameterOptions.firstIndex(of: filament.diameter) {
            diameterPickerView.selectRow(diameterIndex, inComponent: 0, animated: false)
        }

        // Set temperature and speed picker selections
        if let printTempIndex = Filament.temperatureOptions.firstIndex(of: filament.printTemperature) {
            printTemperaturePickerView.selectRow(printTempIndex, inComponent: 0, animated: false)
        }

        if let bedTempIndex = Filament.bedTemperatureOptions.firstIndex(of: filament.bedTemperature) {
            bedTemperaturePickerView.selectRow(bedTempIndex, inComponent: 0, animated: false)
        }

        if let fanSpeedIndex = Filament.fanSpeedOptions.firstIndex(of: filament.fanSpeed) {
            fanSpeedPickerView.selectRow(fanSpeedIndex, inComponent: 0, animated: false)
        }

        if let printSpeedIndex = Filament.printSpeedOptions.firstIndex(of: filament.printSpeed) {
            printSpeedPickerView.selectRow(printSpeedIndex, inComponent: 0, animated: false)
        }
    }

    private func setDefaultValues() {
        // Set default brand (first one - Anycubic)
        let defaultBrand = Filament.Brand.anycubic
        brandTextField.text = defaultBrand.rawValue
        if let index = availableBrands.firstIndex(of: defaultBrand.rawValue) {
            brandPickerView.selectRow(index, inComponent: 0, animated: false)
        }

        // Set default material (PLA)
        let defaultMaterial = Filament.Material.pla
        materialTextField.text = defaultMaterial.rawValue
        materialPickerView.selectRow(0, inComponent: 0, animated: false)

        // Set default color (Black)
        let defaultColor = Filament.Color.black
        colorTextField.text = defaultColor.rawValue
        colorPickerView.selectRow(0, inComponent: 0, animated: false)

        // Set default weight and diameter with proper formatting
        let defaultWeight = defaultBrand.defaultWeight
        weightTextField.text = defaultWeight < 1000 ? String(format: "%.0f g", defaultWeight) : String(format: "%.1f kg", defaultWeight / 1000)
        if let weightIndex = Filament.weightOptions.firstIndex(of: defaultWeight) {
            weightPickerView.selectRow(weightIndex, inComponent: 0, animated: false)
        }

        let defaultDiameter = defaultBrand.defaultDiameter
        diameterTextField.text = String(format: "%.2f mm", defaultDiameter)
        if let diameterIndex = Filament.diameterOptions.firstIndex(of: defaultDiameter) {
            diameterPickerView.selectRow(diameterIndex, inComponent: 0, animated: false)
        }

        // Apply material-based defaults for temperatures and speeds with proper formatting
        let printTemp = defaultMaterial.defaultPrintTemperature
        let bedTemp = defaultMaterial.defaultBedTemperature
        let fanSpeed = defaultMaterial.defaultFanSpeed
        let printSpeed = defaultMaterial.defaultPrintSpeed

        printTemperatureTextField.text = "\(printTemp)°C"
        bedTemperatureTextField.text = "\(bedTemp)°C"
        fanSpeedTextField.text = "\(fanSpeed)%"
        printSpeedTextField.text = "\(printSpeed) mm/s"

        // Set picker selections for temperatures and speeds
        if let printTempIndex = Filament.temperatureOptions.firstIndex(of: printTemp) {
            printTemperaturePickerView.selectRow(printTempIndex, inComponent: 0, animated: false)
        }
        if let bedTempIndex = Filament.bedTemperatureOptions.firstIndex(of: bedTemp) {
            bedTemperaturePickerView.selectRow(bedTempIndex, inComponent: 0, animated: false)
        }
        if let fanSpeedIndex = Filament.fanSpeedOptions.firstIndex(of: fanSpeed) {
            fanSpeedPickerView.selectRow(fanSpeedIndex, inComponent: 0, animated: false)
        }
        if let printSpeedIndex = Filament.printSpeedOptions.firstIndex(of: printSpeed) {
            printSpeedPickerView.selectRow(printSpeedIndex, inComponent: 0, animated: false)
        }
    }

    private func initializeBrands() {
        // Start with predefined brands (sorted alphabetically)
        availableBrands = Filament.Brand.sortedCases.map { $0.rawValue }
        // Add "Add Custom Brand..." option at the end
        availableBrands.append("Add Custom Brand...")
    }

    private func initializeColors() {
        // Get all available colors (predefined + custom)
        availableColors = Filament.Color.allAvailableColors
        // Add "Add Custom Color..." option at the end
        availableColors.append(("Add Custom Color...", UIColor.systemBlue))
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

        // Parse weight from formatted text (e.g., "1000 g" or "1.0 kg")
        let weightText = weightTextField.text ?? "1000"
        let weight: Double
        if weightText.contains("kg") {
            let weightString = weightText.replacingOccurrences(of: " kg", with: "")
            weight = (Double(weightString) ?? 1.0) * 1000
        } else {
            let weightString = weightText.replacingOccurrences(of: " g", with: "")
            weight = Double(weightString) ?? 1000
        }

        // Parse diameter from formatted text (e.g., "1.75 mm")
        let diameterText = diameterTextField.text ?? "1.75"
        let diameterString = diameterText.replacingOccurrences(of: " mm", with: "")
        let diameter = Double(diameterString) ?? 1.75

        // Parse temperatures from formatted text (e.g., "200°C")
        let printTempText = printTemperatureTextField.text ?? "200"
        let printTempString = printTempText.replacingOccurrences(of: "°C", with: "")
        let printTemp = Int(printTempString) ?? 200

        let bedTempText = bedTemperatureTextField.text ?? "60"
        let bedTempString = bedTempText.replacingOccurrences(of: "°C", with: "")
        let bedTemp = Int(bedTempString) ?? 60

        // Parse fan speed from formatted text (e.g., "100%")
        let fanSpeedText = fanSpeedTextField.text ?? "100"
        let fanSpeedString = fanSpeedText.replacingOccurrences(of: "%", with: "")
        let fanSpeed = Int(fanSpeedString) ?? 100

        // Parse print speed from formatted text (e.g., "50 mm/s")
        let printSpeedText = printSpeedTextField.text ?? "50"
        let printSpeedString = printSpeedText.replacingOccurrences(of: " mm/s", with: "")
        let printSpeed = Int(printSpeedString) ?? 50

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
              let weight = Int(weightText),
              weight > 0 else {
            showAlert(title: "Invalid Weight", message: "Please enter a valid weight in grams (whole numbers only).")
            return false
        }

        return true
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    // MARK: - Custom Brand Management

    private func showAddCustomBrandAlert() {
        let alert = UIAlertController(title: "Add Custom Brand", message: "Enter the name of the filament brand", preferredStyle: .alert)

        alert.addTextField { textField in
            textField.placeholder = "Brand name"
            textField.autocapitalizationType = .words
        }

        let addAction = UIAlertAction(title: "Add", style: .default) { [weak self] _ in
            guard let self = self,
                  let textField = alert.textFields?.first,
                  let brandName = textField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !brandName.isEmpty else { return }

            // Check if brand already exists
            if !self.availableBrands.contains(brandName) {
                // Insert before "Add Custom Brand..." option
                self.availableBrands.insert(brandName, at: self.availableBrands.count - 1)
                self.brandPickerView.reloadAllComponents()
            }

            // Set the custom brand as selected
            self.brandTextField.text = brandName

            // Select the new brand in the picker
            if let index = self.availableBrands.firstIndex(of: brandName) {
                self.brandPickerView.selectRow(index, inComponent: 0, animated: true)
            }

            self.dismissKeyboard()
        }

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { [weak self] _ in
            // Reset picker to first item (or current selection)
            guard let self = self else { return }
            if let currentBrand = self.brandTextField.text,
               let index = self.availableBrands.firstIndex(of: currentBrand) {
                self.brandPickerView.selectRow(index, inComponent: 0, animated: true)
            } else {
                self.brandPickerView.selectRow(0, inComponent: 0, animated: true)
            }
        }

        alert.addAction(addAction)
        alert.addAction(cancelAction)

        present(alert, animated: true)
    }

    // MARK: - Custom Color Picker

    private func showCustomColorPicker() {
        let customColorPicker = CustomColorPickerViewController()
        customColorPicker.delegate = self

        let navController = UINavigationController(rootViewController: customColorPicker)
        navController.modalPresentationStyle = .pageSheet

        if #available(iOS 15.0, *) {
            if let sheet = navController.sheetPresentationController {
                sheet.detents = [.large()]
                sheet.prefersGrabberVisible = true
            }
        }

        present(navController, animated: true)
    }

    private func refreshColors() {
        // Refresh the colors list and reload the picker
        initializeColors()
        colorPickerView.reloadAllComponents()
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

// MARK: - UIPickerViewDataSource

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
        case 3: // Weight picker
            return Filament.weightOptions.count
        case 4: // Diameter picker
            return Filament.diameterOptions.count
        case 5: // Print temperature picker
            return Filament.temperatureOptions.count
        case 6: // Bed temperature picker
            return Filament.bedTemperatureOptions.count
        case 7: // Fan speed picker
            return Filament.fanSpeedOptions.count
        case 8: // Print speed picker
            return Filament.printSpeedOptions.count
        default:
            return 0
        }
    }
}

// MARK: - UIPickerViewDelegate

extension AddEditFilamentViewController: UIPickerViewDelegate {

    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        if pickerView.tag == 2 { // Color picker
            let colorInfo = availableColors[row]

            let containerView = UIView()
            containerView.frame = CGRect(x: 0, y: 0, width: 200, height: 30)

            let colorIndicator = UIView()
            colorIndicator.backgroundColor = colorInfo.color
            colorIndicator.layer.cornerRadius = 8
            colorIndicator.layer.borderWidth = 1
            colorIndicator.layer.borderColor = UIColor.systemGray4.cgColor
            colorIndicator.translatesAutoresizingMaskIntoConstraints = false

            let label = UILabel()
            label.text = colorInfo.name
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
            // For all other pickers, use standard text label
            let label = UILabel()
            label.textAlignment = .center
            label.font = UIFont.systemFont(ofSize: 17)
            label.textColor = .label

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
            case 5: // Print temperature picker
                label.text = "\(Filament.temperatureOptions[row])°C"
            case 6: // Bed temperature picker
                label.text = "\(Filament.bedTemperatureOptions[row])°C"
            case 7: // Fan speed picker
                label.text = "\(Filament.fanSpeedOptions[row])%"
            case 8: // Print speed picker
                label.text = "\(Filament.printSpeedOptions[row]) mm/s"
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
        switch pickerView.tag {
        case 0: // Brand picker
            let selectedBrandName = availableBrands[row]

            if selectedBrandName == "Add Custom Brand..." {
                // Show alert to add custom brand
                showAddCustomBrandAlert()
            } else {
                brandTextField.text = selectedBrandName

                // Update weight and diameter defaults when brand changes (only for predefined brands)
                if let predefinedBrand = Filament.Brand.allCases.first(where: { $0.rawValue == selectedBrandName }) {
                    if weightTextField.text?.isEmpty ?? true || weightTextField.text == "1000" {
                        let defaultWeight = predefinedBrand.defaultWeight
                        weightTextField.text = defaultWeight < 1000 ? String(format: "%.0f g", defaultWeight) : String(format: "%.1f kg", defaultWeight / 1000)

                        // Update weight picker selection
                        if let weightIndex = Filament.weightOptions.firstIndex(of: defaultWeight) {
                            weightPickerView.selectRow(weightIndex, inComponent: 0, animated: false)
                        }
                    }
                    if diameterTextField.text?.isEmpty ?? true || diameterTextField.text == "1.75" {
                        let defaultDiameter = predefinedBrand.defaultDiameter
                        diameterTextField.text = String(format: "%.2f mm", defaultDiameter)

                        // Update diameter picker selection
                        if let diameterIndex = Filament.diameterOptions.firstIndex(of: defaultDiameter) {
                            diameterPickerView.selectRow(diameterIndex, inComponent: 0, animated: false)
                        }
                    }
                }
            }

        case 1: // Material picker
            let selectedMaterial = Filament.Material.allCases[row]
            materialTextField.text = selectedMaterial.rawValue

            // Auto-fill temperature and speed defaults based on material
            let printTemp = selectedMaterial.defaultPrintTemperature
            let bedTemp = selectedMaterial.defaultBedTemperature
            let fanSpeed = selectedMaterial.defaultFanSpeed
            let printSpeed = selectedMaterial.defaultPrintSpeed

            printTemperatureTextField.text = "\(printTemp)°C"
            bedTemperatureTextField.text = "\(bedTemp)°C"
            fanSpeedTextField.text = "\(fanSpeed)%"
            printSpeedTextField.text = "\(printSpeed) mm/s"

            // Update picker selections
            if let printTempIndex = Filament.temperatureOptions.firstIndex(of: printTemp) {
                printTemperaturePickerView.selectRow(printTempIndex, inComponent: 0, animated: false)
            }
            if let bedTempIndex = Filament.bedTemperatureOptions.firstIndex(of: bedTemp) {
                bedTemperaturePickerView.selectRow(bedTempIndex, inComponent: 0, animated: false)
            }
            if let fanSpeedIndex = Filament.fanSpeedOptions.firstIndex(of: fanSpeed) {
                fanSpeedPickerView.selectRow(fanSpeedIndex, inComponent: 0, animated: false)
            }
            if let printSpeedIndex = Filament.printSpeedOptions.firstIndex(of: printSpeed) {
                printSpeedPickerView.selectRow(printSpeedIndex, inComponent: 0, animated: false)
            }

        case 2: // Color picker
            let selectedColorInfo = availableColors[row]

            if selectedColorInfo.name == "Add Custom Color..." {
                // Show custom color picker
                showCustomColorPicker()
            } else {
                colorTextField.text = selectedColorInfo.name
            }

        case 3: // Weight picker
            let selectedWeight = Filament.weightOptions[row]
            weightTextField.text = selectedWeight < 1000 ? String(format: "%.0f g", selectedWeight) : String(format: "%.1f kg", selectedWeight / 1000)

        case 4: // Diameter picker
            let selectedDiameter = Filament.diameterOptions[row]
            diameterTextField.text = String(format: "%.2f mm", selectedDiameter)

        case 5: // Print temperature picker
            let selectedTemp = Filament.temperatureOptions[row]
            printTemperatureTextField.text = "\(selectedTemp)°C"

        case 6: // Bed temperature picker
            let selectedTemp = Filament.bedTemperatureOptions[row]
            bedTemperatureTextField.text = "\(selectedTemp)°C"

        case 7: // Fan speed picker
            let selectedSpeed = Filament.fanSpeedOptions[row]
            fanSpeedTextField.text = "\(selectedSpeed)%"

        case 8: // Print speed picker
            let selectedSpeed = Filament.printSpeedOptions[row]
            printSpeedTextField.text = "\(selectedSpeed) mm/s"

        default:
            break
        }
    }
}

// MARK: - UITextFieldDelegate

extension AddEditFilamentViewController {

    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField == brandTextField {
            guard let brandName = textField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !brandName.isEmpty else { return }

            // Check if this is a new custom brand
            if !availableBrands.contains(brandName) && brandName != "Add Custom Brand..." {
                // Insert before "Add Custom Brand..." option
                availableBrands.insert(brandName, at: availableBrands.count - 1)
                brandPickerView.reloadAllComponents()
            }
        }
    }
}

// MARK: - CustomColorPickerDelegate

extension AddEditFilamentViewController: CustomColorPickerDelegate {
    func customColorPicker(_ picker: CustomColorPickerViewController, didSelectColor color: UIColor, withName name: String) {
        // Save the custom color
        CustomColorManager.shared.addCustomColor(name: name, color: color)

        // Refresh the color list
        refreshColors()

        // Set the new color as selected
        colorTextField.text = name

        // Update picker selection to the new color
        if let colorIndex = availableColors.firstIndex(where: { $0.name == name }) {
            colorPickerView.selectRow(colorIndex, inComponent: 0, animated: false)
        }
    }
}
