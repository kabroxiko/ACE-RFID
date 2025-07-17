//
//  AddEditFilamentViewController.swift
//  ACE-RFID
//
//  Created by Copilot on 07/03/2025.
//

import UIKit
import Foundation

protocol AddEditFilamentViewControllerDelegate: AnyObject {
    func didSaveFilament(_ filament: Filament)
}

class AddEditFilamentViewController: UIViewController, UITextFieldDelegate, UIColorPickerViewControllerDelegate {
    // MARK: - Form Fields
    private let brandTextField = UITextField()
    private let materialTextField = UITextField()
    private let colorTextField = UITextField()
    private let weightTextField = UITextField()
    private let diameterTextField = UITextField()
    private let printTempMinTextField = UITextField()
    private let printTempMaxTextField = UITextField()
    private let bedTempMinTextField = UITextField()
    private let bedTempMaxTextField = UITextField()
    private let fanSpeedTextField = UITextField()
    private let printSpeedTextField = UITextField()
    private let notesTextView = UITextView()
    private var colorSwatchView: UIView? // For color swatch updates

    // MARK: - UI Containers
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let stackView = UIStackView()

    // Assign unique tags for dropdown logic
    private enum TempFieldTag: Int {
        case printMin = 5
        case printMax = 6
        case bedMin = 7
        case bedMax = 8
        case fanSpeed = 9
        case printSpeed = 10
    }
    // MARK: - Custom Dropdown Logic
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
        // Update color swatch if color was selected
        if tag == 2 {
            if selected == "Add Custom Color..." {
                showAddCustomColorAlert()
                return
            }
            if let color = availableColors.first(where: { $0.name == selected })?.color {
                updateColorSwatch(color)
            }
        }
        // Dismiss dropdown
        dismissKeyboard()
    }
    // NFC
    private let nfcService = NFCService()

    // MARK: - Properties

    weak var delegate: AddEditFilamentViewControllerDelegate?
    var filament: Filament?
    private var isEditMode: Bool { return filament != nil }

    // Brand management
    private lazy var availableBrands: [String] = {
        var brands = Filament.Brand.allCases.map { $0.rawValue }.sorted()
        brands.append("Add Custom Brand...")
        return brands
    }()

    // MARK: - Custom Color Management
    private var customColorSelected: UIColor = .systemBlue

    private func showAddCustomColorAlert() {
        let alert = UIAlertController(title: "Add Custom Color", message: "Enter a color name and select a color.", preferredStyle: .alert)

        alert.addTextField { textField in
            textField.placeholder = "Color name"
            textField.autocapitalizationType = .words
        }

        // Add hex input field
        alert.addTextField { textField in
            textField.placeholder = "Hex RGB (e.g. #FFAA00)"
            textField.keyboardType = .asciiCapable
        }

        // Add color preview view
        let previewSize: CGFloat = 32
        let previewView = UIView(frame: CGRect(x: 0, y: 0, width: previewSize, height: previewSize))
        previewView.layer.cornerRadius = previewSize / 2
        previewView.layer.borderWidth = 1
        previewView.layer.borderColor = UIColor.systemGray4.cgColor
        previewView.backgroundColor = customColorSelected

        // Add preview to alert
        alert.view.addSubview(previewView)
        previewView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            previewView.heightAnchor.constraint(equalToConstant: previewSize),
            previewView.widthAnchor.constraint(equalToConstant: previewSize),
            previewView.centerXAnchor.constraint(equalTo: alert.view.centerXAnchor),
            previewView.topAnchor.constraint(equalTo: alert.view.topAnchor, constant: 70)
        ])

        // Add a color picker view controller
        let colorPickerVC = UIColorPickerViewController()
        colorPickerVC.selectedColor = customColorSelected
        colorPickerVC.supportsAlpha = false
        colorPickerVC.delegate = self

        let pickColorAction = UIAlertAction(title: "Pick Color", style: .default) { [weak self] _ in
            guard let self = self else { return }
            self.present(colorPickerVC, animated: true)
        }

        let addAction = UIAlertAction(title: "Add", style: .default) { [weak self] _ in
            guard let self = self,
                  let nameField = alert.textFields?[0],
                  let colorName = nameField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !colorName.isEmpty else { return }

            var color: UIColor = self.customColorSelected
            if let hexField = alert.textFields?[1], let hexText = hexField.text, !hexText.isEmpty {
                color = UIColor(hex: hexText) ?? self.customColorSelected
            }

            // Add to availableColors
            self.availableColors.append((name: colorName, color: color))
            self.colorTextField.text = colorName
            self.updateColorSwatch(color)
            self.dismissKeyboard()
        }

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)

        alert.addAction(pickColorAction)
        alert.addAction(addAction)
        alert.addAction(cancelAction)

        // Store previewView for delegate update
        self.customColorPreviewView = previewView

        present(alert, animated: true)
    }

    // Store reference for preview update
    private var customColorPreviewView: UIView?

    // MARK: - UIColorPickerViewControllerDelegate
    func colorPickerViewControllerDidSelectColor(_ viewController: UIColorPickerViewController) {
        customColorSelected = viewController.selectedColor
        customColorPreviewView?.backgroundColor = customColorSelected
    }

    // Color management
    private lazy var availableColors: [(name: String, color: UIColor)] = {
        // Use only predefined colors, plus custom color option
        var colors = Filament.Color.allCases.map { ($0.rawValue, $0.displayColor) }
        colors.append((name: "Add Custom Color...", color: .clear))
        return colors
    }()

    // Helper to fill form with filament
    private func fillFormWithFilament(_ filament: Filament) {
        brandTextField.text = filament.brand
        materialTextField.text = filament.material
        colorTextField.text = filament.color
        weightTextField.text = String(format: "%.0f", filament.weight)
        diameterTextField.text = String(format: "%.2f", filament.diameter)
        printTempMinTextField.text = "\(filament.printMinTemperature)°C"
        printTempMaxTextField.text = "\(filament.printMaxTemperature)°C"
        bedTempMinTextField.text = "\(filament.bedMinTemperature)°C"
        bedTempMaxTextField.text = "\(filament.bedMaxTemperature)°C"
        fanSpeedTextField.text = "\(filament.fanSpeed)%"
        printSpeedTextField.text = "\(filament.printSpeed) mm/s"
        notesTextView.text = filament.notes
    }

    // Helper to build filament from form
    private func buildFilamentFromForm() -> Filament? {
        guard let sku = filament?.sku, !sku.isEmpty,
              let brand = brandTextField.text, !brand.isEmpty,
              let material = materialTextField.text, !material.isEmpty,
              let color = colorTextField.text, !color.isEmpty,
              let weightStr = weightTextField.text, let weight = Double(weightStr),
              let diameterStr = diameterTextField.text, let diameter = Double(diameterStr),
              let printMinTempStr = printTempMinTextField.text?.replacingOccurrences(of: "°C", with: ""), let printMinTemp = Int(printMinTempStr),
              let printMaxTempStr = printTempMaxTextField.text?.replacingOccurrences(of: "°C", with: ""), let printMaxTemp = Int(printMaxTempStr),
              let bedMinTempStr = bedTempMinTextField.text?.replacingOccurrences(of: "°C", with: ""), let bedMinTemp = Int(bedMinTempStr),
              let bedMaxTempStr = bedTempMaxTextField.text?.replacingOccurrences(of: "°C", with: ""), let bedMaxTemp = Int(bedMaxTempStr),
              let fanSpeedStr = fanSpeedTextField.text?.replacingOccurrences(of: "%", with: ""), let fanSpeed = Int(fanSpeedStr),
              let printSpeedStr = printSpeedTextField.text?.replacingOccurrences(of: " mm/s", with: ""), let printSpeed = Int(printSpeedStr)
        else { return nil }

        return Filament(
            sku: sku,
            brand: brand,
            material: material,
            color: color,
            weight: weight,
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

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigationBar()
        fillFormWithFilament()
        // Removed addNFCButtons() and preWarmPickers() calls (not needed for modal dropdowns)
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

    // MARK: - Picker Performance Optimization

    // Picker pre-warm and getCachedPickerView removed for modal dropdown refactor

    private func refreshColors() {
        // Only reload if colors actually changed to avoid unnecessary work
        let newColors = Filament.Color.allCases.map { ($0.rawValue, $0.displayColor) }

        let hasChanged = newColors.count != availableColors.count ||
                        !zip(newColors, availableColors).allSatisfy { $0.0.0 == $0.1.0 }

        if hasChanged {
            availableColors = newColors
            // Picker logic removed for modal dropdowns
        }
    }

    // MARK: - Setup

    private func setupUI() {
        // Enhanced background with gradient
        view.backgroundColor = .systemBackground

        // Add subtle gradient background
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [
            UIColor.systemBackground.cgColor,
            UIColor.secondarySystemBackground.cgColor
        ]
        gradientLayer.locations = [0, 1]
        view.layer.insertSublayer(gradientLayer, at: 0)

        // Update gradient frame when view layout changes - optimized
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            gradientLayer.frame = self.view.bounds
        }

        // Scroll view setup with enhanced styling
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = true
        scrollView.alwaysBounceVertical = true
        scrollView.backgroundColor = .clear

        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.backgroundColor = .clear

        // Stack view setup with enhanced spacing
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 24 // Increased spacing for better visual hierarchy
        stackView.distribution = .fill

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(stackView)

        // Setup form fields
        setupFormFields()

        // Enhanced constraints with better margins
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

        // Enhance navigation bar appearance
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .automatic

        // Enhanced cancel button
        let cancelButton = UIBarButtonItem(
            title: "Cancel",
            style: .plain,
            target: self,
            action: #selector(cancelTapped)
        )
        cancelButton.tintColor = .systemRed
        navigationItem.leftBarButtonItem = cancelButton

        // Enhanced save button
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
        // Brand section
        stackView.addArrangedSubview(createSectionLabel("Brand"))
        brandTextField.placeholder = "Enter brand name or select from list"
        brandTextField.delegate = self
        stackView.addArrangedSubview(createFormField(brandTextField))

        // Material and Color side by side
        materialTextField.placeholder = "Select material"
        materialTextField.delegate = self
        colorTextField.placeholder = "Select color"
        colorTextField.delegate = self
        stackView.addArrangedSubview(createSideBySideFormFields(materialTextField, leftLabel: "Material", colorTextField, rightLabel: "Color"))

        // Weight and Diameter side by side
        weightTextField.placeholder = "Select weight"
        weightTextField.delegate = self
        diameterTextField.placeholder = "Select diameter"
        diameterTextField.delegate = self
        stackView.addArrangedSubview(createSideBySideFormFields(weightTextField, leftLabel: "Weight", diameterTextField, rightLabel: "Diameter"))

        // Print Temperature Min/Max side by side (use class properties)
        printTempMinTextField.placeholder = "Min"
        printTempMinTextField.delegate = self
        printTempMaxTextField.placeholder = "Max"
        printTempMaxTextField.delegate = self
        stackView.addArrangedSubview(createSideBySideFormFields(printTempMinTextField, leftLabel: "Print Temp Min", printTempMaxTextField, rightLabel: "Print Temp Max"))

        // Bed Temperature Min/Max side by side (use class properties)
        bedTempMinTextField.placeholder = "Min"
        bedTempMinTextField.delegate = self
        bedTempMaxTextField.placeholder = "Max"
        bedTempMaxTextField.delegate = self
        stackView.addArrangedSubview(createSideBySideFormFields(bedTempMinTextField, leftLabel: "Bed Temp Min", bedTempMaxTextField, rightLabel: "Bed Temp Max"))

        // Fan Speed and Print Speed side by side
        fanSpeedTextField.placeholder = "Select fan speed"
        fanSpeedTextField.delegate = self
        printSpeedTextField.placeholder = "Select print speed"
        printSpeedTextField.delegate = self
        stackView.addArrangedSubview(createSideBySideFormFields(fanSpeedTextField, leftLabel: "Fan Speed", printSpeedTextField, rightLabel: "Print Speed"))

        // Notes section
        stackView.addArrangedSubview(createSectionLabel("Notes"))
        setupNotesTextView()
        stackView.addArrangedSubview(notesTextView)

        // Add toolbar to all text fields for easy dismissal
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

        // Add subtle shadow for consistency
        notesTextView.layer.shadowColor = UIColor.black.cgColor
        notesTextView.layer.shadowOffset = CGSize(width: 0, height: 1)
        notesTextView.layer.shadowOpacity = 0.05
        notesTextView.layer.shadowRadius = 2

        notesTextView.heightAnchor.constraint(equalToConstant: 120).isActive = true
    }

    private func addToolbarToPickers() {
        // Create individual toolbars for each field to avoid constraint conflicts
        let textFields = [
            brandTextField, materialTextField, colorTextField, weightTextField,
            diameterTextField, printTempMinTextField, printTempMaxTextField,
            bedTempMinTextField, bedTempMaxTextField, fanSpeedTextField,
            printSpeedTextField
        ]

        for textField in textFields {
            textField.inputAccessoryView = createInputToolbar()
        }

        // Add toolbar to notes text view
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

        // Add subtle margin at bottom
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

        // Add subtle shadow for depth
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

        // Add dropdown arrow with better styling
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

        // Add subtle shadow for depth
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

        // Create color swatch view
        let colorSwatchView = UIView()
        colorSwatchView.layer.cornerRadius = 12
        colorSwatchView.layer.borderWidth = 2
        colorSwatchView.layer.borderColor = UIColor.systemGray3.cgColor
        colorSwatchView.backgroundColor = .systemBlue // Default color
        colorSwatchView.translatesAutoresizingMaskIntoConstraints = false

        // Add subtle shadow to make it more visible
        colorSwatchView.layer.shadowColor = UIColor.black.cgColor
        colorSwatchView.layer.shadowOffset = CGSize(width: 0, height: 1)
        colorSwatchView.layer.shadowOpacity = 0.3
        colorSwatchView.layer.shadowRadius = 2

        // Add dropdown arrow with better styling
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

        // Store the color swatch view reference for later updates
        containerView.tag = 999 // Special tag to identify color field container
        colorSwatchView.tag = 1000 // Special tag to identify color swatch

        // Cache the color swatch for fast access
        self.colorSwatchView = colorSwatchView

        return containerView
    }

    private func createSideBySideFormFields(_ leftField: UITextField, leftLabel: String, _ rightField: UITextField, rightLabel: String) -> UIView {
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false

        // Create horizontal stack view
        let horizontalStack = UIStackView()
        horizontalStack.axis = .horizontal
        horizontalStack.spacing = 16
        horizontalStack.distribution = .fillEqually
        horizontalStack.translatesAutoresizingMaskIntoConstraints = false

        // Create left side container
        let leftContainer = UIView()
        let leftLabelView = createFieldLabel(leftLabel)
        let leftFieldView = createFormField(leftField)

        leftContainer.addSubview(leftLabelView)
        leftContainer.addSubview(leftFieldView)
        leftContainer.translatesAutoresizingMaskIntoConstraints = false

        // Create right side container
        let rightContainer = UIView()
        let rightLabelView = createFieldLabel(rightLabel)
        let rightFieldView = rightField == colorTextField ? createColorFormField(rightField) : createFormField(rightField)

        rightContainer.addSubview(rightLabelView)
        rightContainer.addSubview(rightFieldView)
        rightContainer.translatesAutoresizingMaskIntoConstraints = false

        // Add containers to horizontal stack
        horizontalStack.addArrangedSubview(leftContainer)
        horizontalStack.addArrangedSubview(rightContainer)

        containerView.addSubview(horizontalStack)

        NSLayoutConstraint.activate([
            // Horizontal stack constraints
            horizontalStack.topAnchor.constraint(equalTo: containerView.topAnchor),
            horizontalStack.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            horizontalStack.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            horizontalStack.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),

            // Left container constraints
            leftLabelView.topAnchor.constraint(equalTo: leftContainer.topAnchor),
            leftLabelView.leadingAnchor.constraint(equalTo: leftContainer.leadingAnchor),
            leftLabelView.trailingAnchor.constraint(equalTo: leftContainer.trailingAnchor),

            leftFieldView.topAnchor.constraint(equalTo: leftLabelView.bottomAnchor, constant: 8),
            leftFieldView.leadingAnchor.constraint(equalTo: leftContainer.leadingAnchor),
            leftFieldView.trailingAnchor.constraint(equalTo: leftContainer.trailingAnchor),
            leftFieldView.bottomAnchor.constraint(equalTo: leftContainer.bottomAnchor),

            // Right container constraints
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
        printTempMinTextField.text = "\(filament.printMinTemperature)°C"
        printTempMaxTextField.text = "\(filament.printMaxTemperature)°C"
        bedTempMinTextField.text = "\(filament.bedMinTemperature)°C"
        bedTempMaxTextField.text = "\(filament.bedMaxTemperature)°C"
        printSpeedTextField.text = "\(filament.printSpeed) mm/s"
        notesTextView.text = filament.notes

        // Update color swatch to match selected color
        if let selectedColor = availableColors.first(where: { $0.name == filament.color })?.color {
            updateColorSwatch(selectedColor)
        }
    }

    private func setDefaultValues() {
        // Set default brand (first one - Anycubic)
        let defaultBrand = Filament.Brand.anycubic
        brandTextField.text = defaultBrand.rawValue
        // Picker selection logic removed for modal dropdowns

        // Set default material (PLA)
        let defaultMaterial = Filament.Material.pla
        materialTextField.text = defaultMaterial.rawValue
        // Picker selection logic removed for modal dropdowns

        // Set default color (Black)
        let defaultColor = Filament.Color.black
        colorTextField.text = defaultColor.rawValue
        // Set default color swatch to match default color
        updateColorSwatch(defaultColor.displayColor)

        // Set default weight and diameter with proper formatting
        let defaultWeight = defaultBrand.defaultWeight
        weightTextField.text = defaultWeight < 1000 ? String(format: "%.0f g", defaultWeight) : String(format: "%.1f kg", defaultWeight / 1000)
        // Picker selection logic removed for modal dropdowns

        let defaultDiameter = defaultBrand.defaultDiameter
        diameterTextField.text = String(format: "%.2f mm", defaultDiameter)
        // Picker selection logic removed for modal dropdowns

        // Apply material-based defaults for temperatures and speeds with proper formatting
        let printTemp = defaultMaterial.defaultPrintTemperature
        let bedTemp = defaultMaterial.defaultBedTemperature
        let fanSpeed = defaultMaterial.defaultFanSpeed
        let printSpeed = defaultMaterial.defaultPrintSpeed

        printTempMinTextField.text = "\(printTemp)°C"
        printTempMaxTextField.text = "\(printTemp)°C"
        bedTempMinTextField.text = "\(bedTemp)°C"
        bedTempMaxTextField.text = "\(bedTemp)°C"
        fanSpeedTextField.text = "\(fanSpeed)%"
        printSpeedTextField.text = "\(printSpeed) mm/s"

        // Set picker selections for temperatures and speeds
        // Picker selection logic removed for modal dropdowns
    }

    private func initializeBrands() {
        // Start with predefined brands (sorted alphabetically)
        availableBrands = Filament.Brand.sortedCases.map { $0.rawValue }
        // Add "Add Custom Brand..." option at the end
        availableBrands.append("Add Custom Brand...")
    }

    // MARK: - Actions

    @objc private func cancelTapped() {
        dismiss(animated: true)
    }

    @objc private func saveTapped() {
        guard validateForm() else { return }

        let sku = filament?.sku ?? ""
        let brand = brandTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let material = materialTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let color = colorTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        // Parse weight from formatted text (e.g., "1000 g", "1.0 kg", or just numbers)
        let weightText = weightTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "1000"
        let weight: Double
        if weightText.contains("kg") {
            let weightString = weightText.replacingOccurrences(of: "kg", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
            weight = (Double(weightString) ?? 1.0) * 1000
        } else if weightText.contains("g") {
            let weightString = weightText.replacingOccurrences(of: "g", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
            weight = Double(weightString) ?? 1000
        } else {
            // Handle plain numbers (assume grams)
            weight = Double(weightText) ?? 1000
        }

        // Parse diameter from formatted text (e.g., "1.75 mm")
        let diameterText = diameterTextField.text ?? "1.75"
        let diameterString = diameterText.replacingOccurrences(of: " mm", with: "")
        let diameter = Double(diameterString) ?? 1.75

        // Parse min print temperature
        let printMinTempText = printTempMinTextField.text ?? "180"
        let printMinTempString = printMinTempText.replacingOccurrences(of: "°C", with: "")
        let printMinTemp = Int(printMinTempString) ?? 180

        // Parse max print temperature
        let printMaxTempText = printTempMaxTextField.text ?? "210"
        let printMaxTempString = printMaxTempText.replacingOccurrences(of: "°C", with: "")
        let printMaxTemp = Int(printMaxTempString) ?? 210

        let bedMinTempText = bedTempMinTextField.text ?? "50"
        let bedMinTempString = bedMinTempText.replacingOccurrences(of: "°C", with: "")
        let bedMinTemp = Int(bedMinTempString) ?? 50

        let bedMaxTempText = bedTempMaxTextField.text ?? "60"
        let bedMaxTempString = bedMaxTempText.replacingOccurrences(of: "°C", with: "")
        let bedMaxTemp = Int(bedMaxTempString) ?? 60

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

            // Calculate the remaining percentage before updating weight
            let remainingPercentage = updatedFilament.weight > 0 ? (updatedFilament.remainingWeight / updatedFilament.weight) : 1.0

            updatedFilament.brand = brand
            updatedFilament.material = material
            updatedFilament.color = color
            updatedFilament.weight = weight
            updatedFilament.diameter = diameter
            updatedFilament.printMinTemperature = printMinTemp
            updatedFilament.printMaxTemperature = printMaxTemp
            updatedFilament.bedMinTemperature = bedMinTemp
            updatedFilament.bedMaxTemperature = bedMaxTemp
            updatedFilament.fanSpeed = fanSpeed
            updatedFilament.printSpeed = printSpeed
            updatedFilament.notes = notes?.isEmpty == true ? nil : notes

            // Update remaining weight to maintain the same percentage
            updatedFilament.remainingWeight = weight * remainingPercentage

            CoreDataManager.shared.updateFilament(updatedFilament)
            delegate?.didSaveFilament(updatedFilament)
        } else {
            // Create new filament
            let newFilament = Filament(
                sku: sku,
                brand: brand,
                material: material,
                color: color,
                weight: weight,
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

        return true
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private func updateColorSwatch(_ color: UIColor) {
        // Use cached reference for instant updates
        colorSwatchView?.backgroundColor = color
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
            }
            // Set the custom brand as selected
            self.brandTextField.text = brandName
            self.dismissKeyboard()
        }

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { [weak self] _ in
            // Reset picker to first item (or current selection)
            guard let self = self else { return }
            // Picker selection logic removed for modal dropdowns
        }

        alert.addAction(addAction)
        alert.addAction(cancelAction)

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

// MARK: - UIPickerViewDelegate

extension AddEditFilamentViewController: UIPickerViewDelegate {

    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        if pickerView.tag == 2 { // Color picker
            // Reuse views for better performance
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
            // Reuse labels for other pickers
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
        // Picker selection logic removed for modal dropdowns
        // ...existing code...
    }
}

// MARK: - UITextFieldDelegate

extension AddEditFilamentViewController {

    // Show dropdown for dropdown fields and prevent keyboard
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

            // Check if this is a new custom brand
            if !availableBrands.contains(brandName) && brandName != "Add Custom Brand..." {
                // Insert before "Add Custom Brand..." option
                availableBrands.insert(brandName, at: availableBrands.count - 1)
                // Picker logic removed for modal dropdowns
            }
        }
    }
}

// MARK: - UIColor Hex Extension
extension UIColor {
    convenience init?(hex: String) {
        var hexString = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if hexString.hasPrefix("#") {
            hexString.remove(at: hexString.startIndex)
        }
        if hexString.count == 6 {
            hexString += "FF" // Add alpha if missing
        }
        guard hexString.count == 8 else { return nil }
        var rgbValue: UInt64 = 0
        Scanner(string: hexString).scanHexInt64(&rgbValue)
        let r = CGFloat((rgbValue & 0xFF000000) >> 24) / 255.0
        let g = CGFloat((rgbValue & 0x00FF0000) >> 16) / 255.0
        let b = CGFloat((rgbValue & 0x0000FF00) >> 8) / 255.0
        let a = CGFloat(rgbValue & 0x000000FF) / 255.0
        self.init(red: r, green: g, blue: b, alpha: a)
    }
}
